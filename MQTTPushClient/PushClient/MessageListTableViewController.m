/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "MessageTableViewCell.h"
#import "MessageListTableViewController.h"
#import "CDMessage+CoreDataClass.h"

@interface MessageListTableViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashBarButtonItem;
@property NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSFetchedResultsController<CDMessage *> *frc;

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
	[connection getFcmDataForAccount:self.account];
	[self.refreshControl endRefreshing];
}

- (IBAction)trashAction:(UIBarButtonItem *)sender {
	NSManagedObjectContext *bgContext =self.account.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[self.account.backgroundContext
											 existingObjectWithID:self.account.cdaccount.objectID
											 error:NULL];
		if (cdaccount == nil) {
			return;
		}
		cdaccount.messages = nil;
		[bgContext save:NULL];
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Message List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccount) forControlEvents:UIControlEventValueChanged];
	self.tableViewHeaderLabel.text = [NSString stringWithFormat:@"%@@%@", self.account.mqttUser, self.account.mqttHost];
	self.tableView.tableHeaderView = self.tableViewHeaderLabel;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountStatus:) name:@"ServerUpdateNotification" object:nil];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateStyle = NSDateFormatterNoStyle;
	self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	[self.navigationController setToolbarHidden:NO animated:YES];
	[self updateAccountStatus:nil];
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
	cell.dateLabel.text = [self.dateFormatter stringFromDate:cdmessage.timestamp];
	cell.topicLabel.text = cdmessage.topic;
	cell.messageLabel.text = cdmessage.text;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController<CDMessage *> *)frc {
	if (_frc != nil) {
		return _frc;
	}
	
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@", self.account.cdaccount];
	fetchRequest.predicate = predicate;
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	fetchRequest.sortDescriptors = @[sortDescriptor];
	
	NSFetchedResultsController<CDMessage *> *aFrc = [[NSFetchedResultsController alloc]
													 initWithFetchRequest:fetchRequest
													 managedObjectContext:self.account.context
													 sectionNameKeyPath:nil cacheName:nil];
	aFrc.delegate = self;
	[aFrc performFetch:NULL];
	
	self.trashBarButtonItem.enabled = aFrc.fetchedObjects.count > 0;
	
	_frc = aFrc;
	return _frc;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
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
	self.trashBarButtonItem.enabled = controller.fetchedObjects.count > 0;
}

@end
