/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
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
	[self presentViewController:safariViewController animated:YES completion:^{}];
}

- (IBAction)helpAction:(UIButton *)sender {
	NSURL *url = [NSURL URLWithString:@"https://help.radioshuttle.de/mqttapp/1.0/"];
	SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
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
