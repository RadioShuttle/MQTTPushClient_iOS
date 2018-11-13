/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import SafariServices;
#import "PrivacyPolicyTableViewController.h"

@interface PrivacyPolicyTableViewController ()

@end

@implementation PrivacyPolicyTableViewController

- (IBAction)privacyPolicyAction:(UIButton *)sender {
	NSURL *url = [NSURL URLWithString:@"https://www.helios.de/web/EN/privacy.html"];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

@end
