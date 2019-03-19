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
	NSString *urlString = @"https://www.helios.de/web/EN/privacy.html";
	if ([[[NSLocale preferredLanguages] firstObject] hasPrefix:@"de"]) {
		urlString = @"https://www.helios.de/web/DE/privacy.html";
	}
	NSURL *url = [NSURL URLWithString:urlString];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

@end
