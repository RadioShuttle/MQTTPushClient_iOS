/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "WebViewController.h"
#import "AboutTableViewController.h"

@interface AboutTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation AboutTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
	NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString* version = [infoDict objectForKey:@"CFBundleShortVersionString"];
	NSString *text = [NSString stringWithFormat:@"Version: %@", version];
	self.versionLabel.text = text;
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	NSString *identifier = segue.identifier;
	if ([identifier isEqualToString:@"IDWebSite"]) {
		WebViewController *controller = segue.destinationViewController;
		NSURL *url = [NSURL URLWithString:@"www.radioshuttle.de"];
		controller.request = [NSMutableURLRequest requestWithURL:url];
	} else if ([identifier isEqualToString:@"IDHelp"]) {
		WebViewController *controller = segue.destinationViewController;
		NSURL *url = [NSURL URLWithString:@"helios.de"];
		controller.request = [NSMutableURLRequest requestWithURL:url];
	}
}


@end
