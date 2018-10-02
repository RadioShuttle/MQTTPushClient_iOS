/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "AppDelegate.h"
#import "MessageListTableViewController.h"
#import "ServerSetupTableViewController.h"
#import "ServerListTableViewCell.h"
#import "ServerListTableViewController.h"

@interface ServerListTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addServerBarButtonItem;
@property NSMutableArray *accountList;
@property NSIndexPath *indexPathSelected;
@property BOOL statusOK;

@end

@implementation ServerListTableViewController

- (void)updateList:(NSNotification *)sender {
	self.statusOK = YES;
	[self.tableView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	self.addServerBarButtonItem.enabled = editing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.addServerBarButtonItem.enabled = self.editing;
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	self.accountList = appDelegate.accountList;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.statusOK = NO;
	[self.tableView reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:@"ServerUpdateNotification" object:nil];
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
	NSString *text = [NSString stringWithFormat:@"%@@%@:%d", account.mqtt.user, account.mqtt.host, account.mqtt.port.intValue];
	if (self.statusOK)
		cell.imageView.image = [UIImage imageNamed:@"Success"];
	else
		cell.imageView.image = [UIImage imageNamed:@"Error"];
	cell.serverNameLabel.text = text;
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.accountList removeObjectAtIndex:[indexPath row]];
		UIApplication *app = [UIApplication sharedApplication];
		AppDelegate *appDelegate = (AppDelegate *)app.delegate;
		[appDelegate saveAccounts];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	NSMutableArray *accountList = appDelegate.accountList;
	Account *account = accountList[sourceIndexPath.row];
	[accountList removeObjectAtIndex:sourceIndexPath.row];
	[accountList insertObject:account atIndex:destinationIndexPath.row];
	[appDelegate saveAccounts];
}

#pragma mark - navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.indexPathSelected = indexPath;
	if (self.tableView.editing)
		[self performSegueWithIdentifier:@"IDShowSettings" sender:nil];
	else
		[self performSegueWithIdentifier:@"IDShowMessage" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"IDAddServer"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.indexPath = nil;
	} else if ([segue.identifier isEqualToString:@"IDShowSettings"]) {
		ServerSetupTableViewController *controller = segue.destinationViewController;
		controller.accountList = self.accountList;
		controller.indexPath = [self.tableView indexPathForSelectedRow];
	} else {
		MessageListTableViewController *controller = segue.destinationViewController;
		Account *account = self.accountList[self.indexPathSelected.row];
		controller.account = account;
	}
}

@end
