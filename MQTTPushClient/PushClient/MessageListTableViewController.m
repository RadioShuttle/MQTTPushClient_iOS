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

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashBarButtonItem;
@property NSDateFormatter *dateFormatter;

@end

@implementation MessageListTableViewController

- (void)updateList:(NSNotification *)sender {
	[self.tableView reloadData];
//	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateAccountStatus:(NSNotification *)sender {
	if (self.account.error) {
		self.statusLabel.text = self.account.error.localizedDescription;
		[self.navigationController setToolbarHidden:NO animated:YES];
	} else {
		self.statusLabel.text = @"";
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
}

- (void)updateAccount {
	Connection *connection = [[Connection alloc] init];
	[connection getFcmDataForAccount:self.account];
	[self.refreshControl endRefreshing];
}

- (IBAction)trashAction:(UIBarButtonItem *)sender {
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Message List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccount) forControlEvents:UIControlEventValueChanged];
	self.tableViewHeaderLabel.text = [NSString stringWithFormat:@"%@@%@:%d", self.account.mqtt.user, self.account.mqtt.host, self.account.mqtt.port.intValue];
	self.tableView.tableHeaderView = self.tableViewHeaderLabel;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"MessageNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountStatus:) name:@"ServerUpdateNotification" object:nil];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateStyle = NSDateFormatterNoStyle;
	self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	[self updateAccountStatus:nil];
	if (self.account.messageList.count == 0)
		self.trashBarButtonItem.enabled = NO;
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
