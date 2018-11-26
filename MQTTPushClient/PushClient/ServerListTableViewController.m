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
#import "AccountList.h"

@interface ServerListTableViewController ()

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
	if (editing) {
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationAutomatic];
	} else {
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.tableView.refreshControl = [[UIRefreshControl alloc] init];
	self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Server List" attributes:nil];
	[self.tableView.refreshControl addTarget:self action:@selector(updateAccounts) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.accountList = [AccountList sharedAccountList];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = NO;
	[self updateAccounts];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.editing)
		return 1 + self.accountList.count; // because of entry "add new item" in the UI
    return self.accountList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (self.editing && indexPath.row == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDAddServerCell" forIndexPath:indexPath];
	} else {
		NSUInteger row = self.editing ? indexPath.row - 1 : indexPath.row; // because of entry "add new item" in the UI
		Account *account = self.accountList[row];
		ServerListTableViewCell *serverListTableViewCell = [tableView dequeueReusableCellWithIdentifier:@"IDServerCell" forIndexPath:indexPath];
		if (account.error == nil)
			serverListTableViewCell.statusImageView.image = [UIImage imageNamed:@"Success"];
		else
			serverListTableViewCell.statusImageView.image = [UIImage imageNamed:@"Error"];
		serverListTableViewCell.serverNameLabel.text = account.accountDescription;
		if (account.error)
			serverListTableViewCell.errorMessageLabel.text = [account.error localizedDescription];
		else
			serverListTableViewCell.errorMessageLabel.text = @"Server online";
		serverListTableViewCell.unreadMessagesLabel.text = @"";
		cell = serverListTableViewCell;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
		Account *account = self.accountList[row];
		Connection *connection = [[Connection alloc] init];
		[connection removeTokenForAccount:account];
		[self.accountList[row] clearCache];
		[self.accountList removeAccountAtIndex:row];
		[self.accountList save];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing && indexPath.row == 0)
		return NO;
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSUInteger sourceRow = sourceIndexPath.row - 1; // because of entry "add new item" in the UI
	NSUInteger destinationRow = destinationIndexPath.row - 1; // because of entry "add new item" in the UI
	[self.accountList moveAccountAtIndex:sourceRow toIndex:destinationRow];
	[self.accountList save];
}
#pragma mark - delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

#pragma mark - navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing) {
		if (indexPath.row == 0) {
			[self performSegueWithIdentifier:@"IDAddServer" sender:nil];
		} else {
			NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
			self.indexPathSelected = [NSIndexPath indexPathForRow:row inSection:0];
			[self performSegueWithIdentifier:@"IDShowSettings" sender:nil];
		}
	} else {
		self.indexPathSelected = indexPath;
		[self performSegueWithIdentifier:@"IDShowMessageList" sender:nil];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDAddServer"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.editIndex = -1;
	} else if ([identifier isEqualToString:@"IDShowSettings"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.editIndex = self.indexPathSelected.row;
	} else if ([identifier isEqualToString:@"IDShowMessageList"]) {
		MessageListTableViewController *controller = segue.destinationViewController;
		Account *account = self.accountList[self.indexPathSelected.row];
		controller.account = account;
	}
}

@end
