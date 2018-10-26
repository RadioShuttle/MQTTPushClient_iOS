/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Topic.h"
#import "AddTopicTableViewController.h"

@interface AddTopicTableViewController ()

@end

@implementation AddTopicTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	Connection *connection = [[Connection alloc] init];
	[connection addTopicForAccount:self.account name:@"bla/test" type:NotificationBanner];
}

@end
