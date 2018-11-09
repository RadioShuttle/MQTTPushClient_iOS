/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "PrivacyPolicyTableViewController.h"

@interface PrivacyPolicyTableViewController ()

@end

@implementation PrivacyPolicyTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

@end
