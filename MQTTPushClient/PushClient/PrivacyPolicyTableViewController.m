/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
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
	if (@available(iOS 13.0, *)) {
		safariViewController.preferredBarTintColor = [UIColor systemBackgroundColor];
		safariViewController.preferredControlTintColor = self.view.tintColor;
	}
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

@end
