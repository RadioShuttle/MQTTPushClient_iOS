/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Action.h"
#import "Account.h"
#import "Connection.h"
#import "PublishContentTableViewController.h"
#import "ActionListTableViewController.h"

@interface ActionListTableViewController ()

@end

@implementation ActionListTableViewController

- (void)updateList:(NSNotification *)sender {
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
	Connection *connection = [[Connection alloc] init];
	[connection getActionsForAccount:self.account];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.account.actionList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IDActionCell" forIndexPath:indexPath];
	Action *action = self.account.actionList[indexPath.row];
	cell.textLabel.text = action.name;
	return cell;
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	PublishContentTableViewController *controller = segue.destinationViewController;
	controller.account = self.account;
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	controller.action = self.account.actionList[indexPath.row];
	controller.messageList = self.messageList;
}

@end
