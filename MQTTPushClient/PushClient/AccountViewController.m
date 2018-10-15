/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "MessageListTableViewController.h"
#import "AccountViewController.h"

@interface AccountViewController ()

@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;

@end

@implementation AccountViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.account.error)
		self.errorMessageLabel.text = [self.account.error localizedDescription];
	else
		self.errorMessageLabel.text = @"";
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	MessageListTableViewController *controller = segue.destinationViewController;
	controller.account = self.account;
}

@end
