/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "AboutTableViewController.h"

@interface AboutTableViewController ()

@end

@implementation AboutTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.toolbarHidden = YES;
}

@end
