/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

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

@end
