/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import SafariServices;
#import "AboutTableViewController.h"

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation AboutTableViewController

- (IBAction)radioshuttleAction:(UIButton *)sender {
	NSURL *url = [NSURL URLWithString:@"https://www.radioshuttle.de"];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
	if (@available(iOS 13.0, *)) {
		safariViewController.preferredBarTintColor = [UIColor systemBackgroundColor];
		safariViewController.preferredControlTintColor = self.view.tintColor;
	}
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

- (IBAction)helpAction:(UIButton *)sender {
	NSURL *url = [NSURL URLWithString:@"https://help.radioshuttle.de/mqttapp/1.0/"];
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
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
	NSString *build = [infoDict objectForKey:@"CFBundleVersion"];
	NSString *text = [NSString stringWithFormat:@"Version: %@ (%@)", version, build];
	self.versionLabel.text = text;
}

@end
