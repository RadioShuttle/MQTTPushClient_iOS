/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "JavaScriptFilter.h"
#import "Account.h"
#import "Connection.h"
#import "CDMessage+CoreDataClass.h"
#import "MessageTableViewCell.h"
#import "ActionListTableViewController.h"
#import "MessageListTableViewController.h"
#import "DashCollectionViewController.h"

@interface MessageListTableViewController () <NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, UISearchResultsUpdating>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property NSDateFormatter *dateFormatter;
@property NSDateFormatter *sectionDateFormatter;
@property (strong, nonatomic) NSFetchedResultsController<CDMessage *> *frc;

@property (strong, nonatomic) UISearchController *topicSearchController;

// These two properties are used to detect new messages and display them with
// a yellow background, until the user scrolls or leaves the view.
@property NSDate *lastViewed;
@property BOOL newMessages;
@property BOOL isAtTop;
@property BOOL javaScriptTimedOut;

@end

@implementation MessageListTableViewController

- (void)updateAccountStatus:(NSNotification *)sender {
	if (self.account.error) {
		self.statusLabel.text = self.account.error.localizedDescription;
	} else {
		self.statusLabel.text = @"";
	}
	self.tableView.tableFooterView.hidden = self.account.topicList.count > 0 || self.frc.fetchedObjects.count > 0;
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
		self.lastViewed = [NSDate date];
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
	self.isAtTop = YES;
	self.tableView.tableFooterView.hidden = YES;

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
	
	// Search Topics SearchController
	self.topicSearchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.topicSearchController.obscuresBackgroundDuringPresentation = NO;
	self.topicSearchController.searchBar.placeholder = @"Search Topics";
	self.topicSearchController.searchResultsUpdater = self;
	self.definesPresentationContext = YES;
	if (@available(iOS 11, *)) {
		self.navigationItem.searchController = self.topicSearchController;
	} else {
		self.tableView.tableHeaderView = self.topicSearchController.searchBar;
	}
	
	self.moreButton.target = self;
	self.moreButton.action = @selector(onMoreButtonClicked);
	
	[self updateAccount];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountStatus:) name:@"ServerUpdateNotification" object:nil];
	[self.navigationController setToolbarHidden:NO animated:YES];
	[self updateAccountStatus:nil];
	
	// Delete messages older than 30 days:
	NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
															value:-30
														   toDate:[NSDate date]
														  options:0];
	[self.account deleteMessagesBefore:date];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.account.cdaccount markMessagesRead];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[Dashboard setPreferredViewDashboard:NO forAccount:self.account];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.frc.sections.count > 0) {
		self.tableView.tableFooterView.hidden = YES;
	}
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
	NSString *topicName = [cdmessage.topic stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	NSString *text = [NSString stringWithFormat:@"%@ – %@", date, topicName];
	NSString *msg = [Message msgFromData:cdmessage.content];
	UIColor *textColor = nil;
	UIColor *backgroundColor = nil;
	cell.dateLabel.text = text;
	if (!self.javaScriptTimedOut) {
		Topic *topic = [self.account topicWithName:topicName];
		if (topic != nil && topic.filterScript.length > 0) {
			NSError *error = nil;
			JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:topic.filterScript];
			NSObject *raw = [filter arrayBufferFromData:cdmessage.content];
			NSDictionary *arg1 = @{@"raw":raw, @"text":msg, @"topic":topic.name, @"receivedDate":cdmessage.timestamp};
			NSDictionary *arg2 = @{@"user":self.account.mqttUser, @"mqttServer":self.account.mqttHost, @"pushServer":self.account.host};
			ViewParameter *viewParameter = [[ViewParameter alloc] init];
			NSString *filtered = [filter filterMsg:arg1 acc:arg2
									  viewParameter:viewParameter
											 error:&error];
			if (filtered) {
				msg = filtered;
				textColor = viewParameter.uiTextColor;
				backgroundColor = viewParameter.uiBackgroundColor;
			} else {
				self.javaScriptTimedOut = YES;
			}
		}
	}
	cell.messageLabel.text = [msg stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	cell.messageLabel.textColor = textColor;
	cell.messageView.backgroundColor = backgroundColor;
	if ([cdmessage.timestamp compare:self.lastViewed] == NSOrderedDescending) {
		if (@available(iOS 13.0, *)) {
			cell.backgroundColor = [UIColor colorNamed:@"Color_Highlight_Msgs"];
		} else {
			cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.0 alpha:1.0]; // Yellow
		}
	} else {
		cell.backgroundColor = [UIColor clearColor];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == self.tableView
		&& scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
		// User initiated scroll.
		self.lastViewed = [NSDate date];
		self.isAtTop = NO;
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

#pragma mark - Search Topics results

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	_frc = nil;
	[self.tableView reloadData];
}


#pragma mark - Fetched results controller

- (NSFetchedResultsController<CDMessage *> *)frc {
	if (_frc != nil) {
		return _frc;
	}
	
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	NSPredicate *predicate;
	if ([self.topicSearchController.searchBar.text length] > 0) {
		predicate = [NSPredicate predicateWithFormat:@"account = %@ AND topic CONTAINS[C] %@", self.account.cdaccount, self.topicSearchController.searchBar.text];
	} else {
		predicate = [NSPredicate predicateWithFormat:@"account = %@", self.account.cdaccount];
	}
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
	if (self.newMessages && !self.isAtTop) {
		self.isAtTop = YES;
		NSIndexPath *topIndex = [NSIndexPath indexPathForRow:0 inSection:0];
		[self.tableView scrollToRowAtIndexPath:topIndex
							  atScrollPosition:UITableViewScrollPositionBottom
									  animated:YES];
	}
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	NSString *identifier = segue.identifier;

	if ([identifier isEqualToString:@"IDShowDashboard"]) {
		DashCollectionViewController *vc = segue.destinationViewController;
		vc.account = self.account;
	} else { //if ([identifier isEqualToString:@"IDShowMqttActions"])
		UIPopoverPresentationController *popOver = segue.destinationViewController.popoverPresentationController;
		popOver.delegate = self;
		
		UINavigationController *nc = segue.destinationViewController;
		ActionListTableViewController *controller = (ActionListTableViewController *)nc.topViewController;
		controller.account = self.account;
		controller.editAllowed = NO;
		
		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
																target:self action:@selector(dismissActionList)];
		controller.navigationItem.rightBarButtonItem = done;
	}
}

- (void)dismissActionList {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onMoreButtonClicked {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:@"MQTT Actions" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performSegueWithIdentifier:@"IDShowMqttActions" sender:self];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Dashboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performSegueWithIdentifier:@"IDShowDashboard" sender:self];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Delete Messages"  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self trashAction:self.moreButton];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	[alert setModalPresentationStyle:UIModalPresentationPopover];
	alert.popoverPresentationController.barButtonItem = self.moreButton;

	[self presentViewController:alert animated:TRUE completion:nil];

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
