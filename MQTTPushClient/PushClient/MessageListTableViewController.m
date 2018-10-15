/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Message.h"
#import "Account.h"
#import "Connection.h"
#import "MessageTableViewCell.h"
#import "MessageListTableViewController.h"

@interface MessageListTableViewController ()

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property NSDateFormatter *dateFormatter;

@end

@implementation MessageListTableViewController

- (void)updateList:(NSNotification *)sender {
	[self.tableView reloadData];
//	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	if (self.account.error)
		self.errorMessageLabel.text = [self.account.error localizedDescription];
	else
		self.errorMessageLabel.text = @"";
}

- (void)updateAccount {
	Connection *connection = [[Connection alloc] init];
	[connection getFcmDataForAccount:self.account];
	[self.refreshControl endRefreshing];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Message List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccount) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"MessageNotification" object:nil];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateStyle = NSDateFormatterNoStyle;
	self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	self.toolbarItems = self.toolbar.items;
	self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.account.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Message *message = self.account.messageList[indexPath.row];
	MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IDMessageCell" forIndexPath:indexPath];
	cell.dateLabel.text = [self.dateFormatter stringFromDate:message.date];
	cell.topicLabel.text = message.topic;
	cell.messageLabel.text = message.text;
	return cell;
}

@end
