/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "CDMessage+CoreDataClass.h"
#import "MessageTableViewCell.h"
#import "ActionListTableViewController.h"
#import "MessageListTableViewController.h"

@interface MessageListTableViewController () <NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashBarButtonItem;
@property NSDateFormatter *dateFormatter;
@property NSDateFormatter *sectionDateFormatter;
@property (strong, nonatomic) NSFetchedResultsController<CDMessage *> *frc;

// These two properties are used to detect new messages and display them with
// a yellow background, until the user scrolls or leaves the view.
@property NSDate *lastViewed;
@property BOOL newMessages;

@end

@implementation MessageListTableViewController

- (void)updateAccountStatus:(NSNotification *)sender {
	if (self.account.error) {
		self.statusLabel.text = self.account.error.localizedDescription;
	} else {
		self.statusLabel.text = @"";
	}
}

- (void)updateAccount {
	Connection *connection = [[Connection alloc] init];
	[connection getMessagesForAccount:self.account];
	[self.refreshControl endRefreshing];
}

- (IBAction)trashAction:(UIBarButtonItem *)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	alert.popoverPresentationController.barButtonItem = sender;

	UIAlertAction *allAction = [UIAlertAction actionWithTitle:@"Delete all messages" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self.account deleteMessagesBefore:nil];
	}];
	UIAlertAction *olderAction = [UIAlertAction actionWithTitle:@"Delete messages older than one day" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
																value:-1
															   toDate:[NSDate date]
															  options:0];
		[self.account deleteMessagesBefore:date];
	}];
	UIAlertAction *restoreAction = [UIAlertAction actionWithTitle:@"Restore messages from server" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self.account restoreMessages];
		[self updateAccount];
	}];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
	[alert addAction:allAction];
	[alert addAction:olderAction];
	[alert addAction:restoreAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Message List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccount) forControlEvents:UIControlEventValueChanged];
	self.tableViewHeaderLabel.text = self.account.accountDescription;
	self.lastViewed = [NSDate date];

	// Formatter for the section headers (one section per day).
	self.sectionDateFormatter = [[NSDateFormatter alloc] init];
	self.sectionDateFormatter.dateStyle = NSDateFormatterLongStyle;
	self.sectionDateFormatter.timeStyle = NSDateFormatterNoStyle;
	self.sectionDateFormatter.doesRelativeDateFormatting = YES;

	// Formatter for the time field in the message cells.
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[self.dateFormatter setLocalizedDateFormatFromTemplate:@"HH:mm"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(significantTimeChange:)
												 name:UIApplicationSignificantTimeChangeNotification
											   object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountStatus:) name:@"ServerUpdateNotification" object:nil];
	[self.navigationController setToolbarHidden:NO animated:YES];
	[self updateAccountStatus:nil];
	[self updateAccount];
	
	// Delete messages older than 30 days:
	NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
															value:-30
														   toDate:[NSDate date]
														  options:0];
	[self.account deleteMessagesBefore:date];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.frc.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
	return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IDMessageCell" forIndexPath:indexPath];
	CDMessage *cdmessage = [self.frc objectAtIndexPath:indexPath];
	[self configureCell:cell withObject:cdmessage];
	return cell;
}

- (void)configureCell:(MessageTableViewCell *)cell withObject:(CDMessage *)cdmessage {
	NSString *date = [self.dateFormatter stringFromDate:cdmessage.timestamp];
	NSString *topic = [cdmessage.topic stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	NSString *text = [NSString stringWithFormat:@"%@ – %@", date, topic];
	cell.dateLabel.text = text;
	cell.messageLabel.text = [cdmessage.content stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	if ([cdmessage.timestamp compare:self.lastViewed] == NSOrderedDescending) {
		cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.0 alpha:1.0]; // Yellow
	} else {
		cell.backgroundColor = [UIColor clearColor];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == self.tableView
		&& scrollView.panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		// User initiated scroll.
		self.lastViewed = [NSDate date];
		for (UITableView *cell in self.tableView.visibleCells) {
			cell.backgroundColor = [UIColor clearColor];
		}
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
	
	/*
	 * Create (localized) date from the section identifier, which is
	 * a string of the form "YYYYMMDD".
	 */
	NSInteger numericSection = sectionInfo.name.integerValue;
	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	dateComponents.day = numericSection % 100;;
	numericSection /= 100;
	dateComponents.month = numericSection % 100;
	numericSection /= 100;
	dateComponents.year = numericSection;
	NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
	
	return [self.sectionDateFormatter stringFromDate:date];
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController<CDMessage *> *)frc {
	if (_frc != nil) {
		return _frc;
	}
	
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@", self.account.cdaccount];
	fetchRequest.predicate = predicate;
	NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:NO];
	fetchRequest.sortDescriptors = @[sort1, sort2];
	
	NSFetchedResultsController<CDMessage *> *aFrc = [[NSFetchedResultsController alloc]
													 initWithFetchRequest:fetchRequest
													 managedObjectContext:self.account.context
													 sectionNameKeyPath:@"sectionIdentifier"
													 cacheName:nil];
	aFrc.delegate = self;
	[aFrc performFetch:NULL];

	_frc = aFrc;
	return _frc;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
	self.newMessages = NO;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		default:
			return;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	UITableView *tableView = self.tableView;
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			self.newMessages = YES;
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath] withObject:anObject];
			break;
			
		case NSFetchedResultsChangeMove:
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath] withObject:anObject];
			[tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
	if (self.newMessages) {
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	}
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)dismiss {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
	UIViewController *presentedViewController = controller.presentedViewController;
	if (style == UIModalPresentationFullScreen || style == UIModalPresentationFormSheet) {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:presentedViewController];
		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
		presentedViewController.navigationItem.rightBarButtonItem = done;
		return navigationController;
	}
	return presentedViewController;
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	ActionListTableViewController *controller = segue.destinationViewController;
	controller.account = self.account;
	controller.editAllowed = NO;
	controller.popoverPresentationController.delegate = self;
}

#pragma mark - Notifications

/*
 * This is fired if a new day has started, or the time zone has been changed.
 * We have to reload re-create the fetched results controller (because sections
 * must be recomputed) and reload the table view.
 */
- (void)significantTimeChange:(NSNotification *)aNotification {
	_frc = nil;
	[self.tableView reloadData];
}

@end
