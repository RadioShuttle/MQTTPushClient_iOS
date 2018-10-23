/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "MessageListTableViewController.h"
#import "ServerSetupTableViewController.h"
#import "ServerListTableViewCell.h"
#import "ServerListTableViewController.h"
#import "TopicsListTableViewController.h"
#import "AccountList.h"

@interface ServerListTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addServerBarButtonItem;
@property AccountList *accountList;
@property NSIndexPath *indexPathSelected;

@end

@implementation ServerListTableViewController

- (void)updateList:(NSNotification *)sender {
	[self.tableView reloadData];
}

- (void)updateAccounts {
	for (Account *account in self.accountList) {
		Connection *connection = [[Connection alloc] init];
		[connection getFcmDataForAccount:account];
	}
	[self.refreshControl endRefreshing];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	self.addServerBarButtonItem.enabled = editing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Server List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccounts) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.addServerBarButtonItem.enabled = self.editing;
	self.accountList = [AccountList sharedAccountList];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
	self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.accountList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Account *account = self.accountList[indexPath.row];
	ServerListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IDServerCell" forIndexPath:indexPath];
	NSString *text = [NSString stringWithFormat:@"%@@%@", account.mqttUser, account.mqttHost];
	if (account.error == nil)
		cell.statusImageView.image = [UIImage imageNamed:@"Success"];
	else
		cell.statusImageView.image = [UIImage imageNamed:@"Error"];
	cell.serverNameLabel.text = text;
	cell.errorMessageLabel.text = [account.error localizedDescription];
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.accountList[indexPath.row] clearCache];
		[self.accountList removeAccountAtIndex:[indexPath row]];
		[self.accountList save];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	[self.accountList moveAccountAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
	[self.accountList save];
}
#pragma mark - delegate

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"IDShowTopics" sender:indexPath];
}

#pragma mark - navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.indexPathSelected = indexPath;
	if (self.tableView.editing)
		[self performSegueWithIdentifier:@"IDShowSettings" sender:nil];
	else
		[self performSegueWithIdentifier:@"IDShowMessageList" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDAddServer"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.indexPath = nil;
	} else if ([identifier isEqualToString:@"IDShowSettings"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.indexPath = [self.tableView indexPathForSelectedRow];
	} else if ([identifier isEqualToString:@"IDShowTopics"]) {
		TopicsListTableViewController *controller = segue.destinationViewController;
		NSIndexPath *indexPath = sender;
		Account *account = self.accountList[indexPath.row];
		controller.account = account;
	} else if ([identifier isEqualToString:@"IDShowMessageList"]) {
		MessageListTableViewController *controller = segue.destinationViewController;
		Account *account = self.accountList[self.indexPathSelected.row];
		controller.account = account;
	}
}

@end
