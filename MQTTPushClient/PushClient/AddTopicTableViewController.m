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
@property (weak, nonatomic) IBOutlet UISegmentedControl *notificationTypeSegmentedControl;

@end

@implementation AddTopicTableViewController

- (IBAction)validateFields:(id)sender {
	self.subscribeBarButtonItem.enabled = self.topicTextField.text.length > 0;
}

- (IBAction)subscribeAction:(UIBarButtonItem *)sender {
	NSString *topic = self.topicTextField.text;
	if (topic.length) {
		Connection *connection = [[Connection alloc] init];
		enum NotificationType type = NotificationDisabled;
		switch (self.notificationTypeSegmentedControl.selectedSegmentIndex) {
			case 2:
				type = NotificationBannerSound;
				break;
			case 1:
				type = NotificationBanner;
				break;
			default:
				type = NotificationNone;
				break;
		}
		[connection addTopicForAccount:self.account name:topic type:type];
		[connection getTopicsForAccount:self.account];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.subscribeBarButtonItem.enabled = NO;
	self.notificationTypeSegmentedControl.selectedSegmentIndex = 2;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
