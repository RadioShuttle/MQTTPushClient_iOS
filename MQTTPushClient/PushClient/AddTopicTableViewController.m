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

- (void)getResult:(NSNotification *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)validateFields:(id)sender {
	self.subscribeBarButtonItem.enabled = self.topicTextField.text.length > 0;
}

- (IBAction)subscribeAction:(UIBarButtonItem *)sender {
	NSString *topicName = self.topicTextField.text;
	if (topicName.length) {
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
		if (self.topic)
			[connection updateTopicForAccount:self.account name:topicName type:type];
		else
			[connection addTopicForAccount:self.account name:topicName type:type];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getResult:) name:@"ServerUpdateNotification" object:nil];
	if (self.topic) {
		self.subscribeBarButtonItem.enabled = YES;
		self.topicTextField.text = self.topic.name;
		self.topicTextField.enabled = NO;
		switch (self.topic.type) {
			case NotificationBannerSound:
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 2;
				break;
			case NotificationBanner:
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 1;
				break;
			default:
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 0;
				break;
		}
	} else {
		self.subscribeBarButtonItem.enabled = NO;
		self.notificationTypeSegmentedControl.selectedSegmentIndex = 2;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
