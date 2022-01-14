/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "AppDelegate.h"
#import "Account.h"
#import "AccountList.h"
#import "Connection.h"
#import "MessageListTableViewController.h"
#import "ServerSetupTableViewController.h"
#import "ServerListTableViewCell.h"
#import "ServerListTableViewController.h"
#import "TokenManager.h"
#import "DashCollectionViewController.h"
#import "DashResourcesHelper.h"

@interface ServerListTableViewController ()

@property AccountList *accountList;
@property NSIndexPath *indexPathSelected;
@property NSInteger interfaceStyle;

@end

@implementation ServerListTableViewController

static NSString * const interface_style_key = @"interface_style";

- (void)updateList:(NSNotification *)sender {
	Account *account = sender.userInfo[@"UpdatedServerKey"];
	if (account != nil) {
		for (NSIndexPath *ip in self.tableView.indexPathsForVisibleRows) {
			if (self.editing && ip.row == 0) {
				continue;
			}
			NSUInteger row = self.editing ? ip.row - 1 : ip.row;
			if (self.accountList[row] == account) {
				[self.tableView reloadRowsAtIndexPaths:@[ip]
									  withRowAnimation:UITableViewRowAnimationAutomatic];
				break;
			}
		}
	} else {
		[self.tableView reloadData];
	}
	[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:NO block:^(NSTimer *timer){
		for (Account *account in self.accountList) {
			if (account.error && account.error.code == SecureTransportError) {
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Security Warning" message:account.error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
				UIAlertAction *allowAction = [UIAlertAction actionWithTitle:@"Allow" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
					account.secureTransportToPushServer = NO;
					account.secureTransportToPushServerDateSet = [NSDate date];
					[self updateAccounts];
				}];
				[alert addAction:allowAction];
				[alert addAction:cancelAction];
				[self presentViewController:alert animated:YES completion:nil];
				alert = nil;
				break;
			}
		}
	}];
}

- (void)updateAccounts {
	for (Account *account in self.accountList) {
		Connection *connection = [[Connection alloc] init];
		if (account.secureTransportToPushServer == NO) {
			NSTimeInterval time = [account.secureTransportToPushServerDateSet timeIntervalSinceNow];
			NSTimeInterval threshold = -24 * 60 * 60;
			if (time < threshold) {
				account.secureTransportToPushServer = YES;
				account.secureTransportToPushServerDateSet = [NSDate date];
			}
		}
		[connection getFcmDataForAccount:account];
		[connection getTopicsForAccount:account];
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
	
	/* dark mode */
	[self addThemeToolbarButton];

	/* dashboard clean up task */
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[DashResourcesHelper deleteLocalImageResources:self.accountList];
	});
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = NO;
	/*
	 * When in editing mode, a new server may be added to the list
	 * with a delay. To avoid an inconsistent table view state during
	 * this delay, we update the table view now.
	 */
	if (self.editing)
		[self.tableView reloadData];
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
		if (account.error == nil) {
			if (account.fcmToken)
				serverListTableViewCell.statusImageView.image = [UIImage imageNamed:@"Success"];
			else
				serverListTableViewCell.statusImageView.image = [UIImage imageNamed:@"Warning"];
		} else
			serverListTableViewCell.statusImageView.image = [UIImage imageNamed:@"Error"];
		serverListTableViewCell.serverNameLabel.text = account.accountDescription;
		if (account.error)
			serverListTableViewCell.errorMessageLabel.text = [account.error localizedDescription];
		else
			serverListTableViewCell.errorMessageLabel.text = @"Server online";
		NSInteger numUnread = account.cdaccount.numUnreadMessages;
		serverListTableViewCell.unreadMessagesLabel.text = numUnread > 0 ? @(numUnread).stringValue : @"";
		cell = serverListTableViewCell;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSUInteger row = indexPath.row - 1; // because of entry "add new item" in the UI
		Account *account = self.accountList[row];
		NSString *fcmSenderID = account.fcmSenderID;

		Connection *connection = [[Connection alloc] init];
		[connection removeDeviceForAccount:account];
		[self.accountList[row] clearCache];
		[self.accountList removeAccountAtIndex:row];
		[self.accountList save];
		
		// Delete FCM token if same sender ID is not used with any remaining account:
		if (fcmSenderID != nil) {
			BOOL deleteFcmToken = YES;
			for (Account *otherAccount in self.accountList) {
				if ([otherAccount.fcmSenderID isEqualToString:fcmSenderID]) {
					deleteFcmToken = NO;
					break;
				}
			}
			if (deleteFcmToken) {
				[[TokenManager sharedTokenManager] deleteTokenFor:fcmSenderID];
			}
		}
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self performSegueWithIdentifier:@"IDAddServer" sender:nil];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
	   toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.row > 0) {
		return proposedDestinationIndexPath;
	} else {
		return [NSIndexPath indexPathForRow:1 inSection:0];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row > 0;
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
		Account *account = self.accountList[self.indexPathSelected.row];
		if ([Dashboard showDashboard:account]) {
			[self performSegueWithIdentifier:@"IDShowDash" sender:nil];
		} else {
			[self performSegueWithIdentifier:@"IDShowMessageList" sender:nil];
		}
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
	} else if ([identifier isEqualToString:@"IDShowDash"]) {
		DashCollectionViewController *controller = segue.destinationViewController;
		Account *account = self.accountList[self.indexPathSelected.row];
		controller.account = account;
	}
}

#pragma mark - theme

-(void)addThemeToolbarButton {
	if (@available(iOS 13.0, *)) {
		NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:interface_style_key];
		self.interfaceStyle = [val integerValue];
		if (self.interfaceStyle > 0) {
			[self updateTheme:self.interfaceStyle];
		}
		UIBarButtonItem *themeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"DarkMode"] style:UIBarButtonItemStylePlain target:self action:@selector(onThemeButtonClicked)];
		NSMutableArray * items = [self.toolbarItems mutableCopy];
		[items addObject:themeButton];
		UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[items addObject:flexItem];
		self.toolbarItems = items;
	}
}

-(void)onThemeButtonClicked {
	if (@available(iOS 13.0, *)) {
		NSString *menuLight = @"Light";
		NSString *menuDark = @"Dark";
		NSString *menuSystem = @"System Default";

		if (self.interfaceStyle == UIDocumentBrowserUserInterfaceStyleDark) {
			menuDark = [NSString stringWithFormat:@"  %@ \u2022", menuDark];
		} else if (self.interfaceStyle == UIDocumentBrowserUserInterfaceStyleLight) {
			menuLight = [NSString stringWithFormat:@"  %@ \u2022", menuLight];
		} else {
			menuSystem = [NSString stringWithFormat:@"  %@ \u2022", menuSystem];
		}
		
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Theme" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		[alert addAction:[UIAlertAction actionWithTitle:menuLight style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self onThemeSelected:UIUserInterfaceStyleLight];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:menuDark style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self onThemeSelected:UIUserInterfaceStyleDark];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:menuSystem  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self onThemeSelected:UIUserInterfaceStyleUnspecified];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		}]];
		[self presentViewController:alert animated:TRUE completion:nil];
	}
}

-(void)onThemeSelected:(UIUserInterfaceStyle) style API_AVAILABLE(ios(12.0)){
	if (style != self.interfaceStyle) {
		self.interfaceStyle = style;
		[self updateTheme:style];
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		[prefs setObject:[[NSNumber numberWithInteger:style] stringValue] forKey:interface_style_key];
		[prefs synchronize];
	}
}

-(void)updateTheme:(UIUserInterfaceStyle) style API_AVAILABLE(ios(12.0)){
	if (@available(iOS 13.0, *)) {
		((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.overrideUserInterfaceStyle = style;
		[self.navigationController.view setNeedsLayout]; // update toolbar. ios bug?
	}
}

@end
