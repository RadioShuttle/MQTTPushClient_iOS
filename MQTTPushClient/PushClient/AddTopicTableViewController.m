/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Topic.h"
#import "AddTopicTableViewController.h"

@interface AddTopicTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *subscribeBarButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *topicTextField;

@end

@implementation AddTopicTableViewController

- (IBAction)validateFields:(id)sender {
	self.subscribeBarButtonItem.enabled = self.topicTextField.text.length > 0;
}

- (IBAction)subscribeAction:(UIBarButtonItem *)sender {
	NSString *topic = self.topicTextField.text;
	if (topic.length) {
		Connection *connection = [[Connection alloc] init];
		[connection addTopicForAccount:self.account name:topic type:NotificationBanner];
		[connection getTopicsForAccount:self.account];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.subscribeBarButtonItem.enabled = NO;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	self.subscribeBarButtonItem.enabled = self.topicTextField.text.length > 0;
	return YES;
}

@end
