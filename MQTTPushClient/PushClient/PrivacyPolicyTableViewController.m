/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "WebViewController.h"
#import "PrivacyPolicyTableViewController.h"

@interface PrivacyPolicyTableViewController ()

@end

@implementation PrivacyPolicyTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	WebViewController *controller = segue.destinationViewController;
	NSURL *url = [NSURL URLWithString:@"helios.de"];
	controller.request = [NSMutableURLRequest requestWithURL:url];
}

@end
