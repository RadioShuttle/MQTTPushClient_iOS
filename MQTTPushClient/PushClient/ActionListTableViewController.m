/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Action.h"
#import "Account.h"
#import "Connection.h"
#import "AddActionTableViewController.h"
#import "ActionListTableViewController.h"

@interface ActionListTableViewController ()

@property Action *action;

@end

@implementation ActionListTableViewController

- (void)updateList:(NSNotification *)sender {
	if (self.action) {
		if (self.account.error) {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:self.account.error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
			[alert addAction:cancelAction];
			[self presentViewController:alert animated:YES completion:nil];
		} else
			[self.navigationController popToViewController:self.messageList animated:YES];
	} else
		[self.tableView reloadData];
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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
	if (self.editing)
		return 1 + self.account.actionList.count; // because of entry "add new item" in the UI
	return self.account.actionList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	if (self.editing && indexPath.row == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDAddActionCell" forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"IDActionCell" forIndexPath:indexPath];
		NSUInteger row = self.editing ? indexPath.row - 1 : indexPath.row; // because of entry "add new item" in the UI
		Action *action = self.account.actionList[row];
		cell.textLabel.text = action.name;
	}
	return cell;
}

#pragma mark - Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.editing) {
		if (indexPath.row == 0) {
			[self performSegueWithIdentifier:@"IDAddAction" sender:nil];
		} else {
			NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
			Action *action = self.account.actionList[row];
			[self performSegueWithIdentifier:@"IDShowAction" sender:action];
		}
	} else {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		self.action = self.account.actionList[indexPath.row];
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"MQTT Action" message:self.action.name preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *sendAction = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			Connection *connection = [[Connection alloc] init];
			[connection publishMessageForAccount:self.account action:self.action];
		}];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
		[alert addAction:sendAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	AddActionTableViewController *controller = segue.destinationViewController;
	controller.account = self.account;
	controller.action = sender;
}

@end
