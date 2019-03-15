/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Topic.h"
#import "ScriptViewController.h"
#import "AddTopicTableViewController.h"

@interface AddTopicTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *subscribeBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *topicTitleLabel;
@property (weak, nonatomic) IBOutlet UITextField *topicTextField;
@property (weak, nonatomic) IBOutlet UILabel *notificationTypeLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *notificationTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UILabel *scriptModifiedLabel;

@end

@implementation AddTopicTableViewController

- (void)getResult:(NSNotification *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)textForNotificationIndex:(NSUInteger)index {
	NSString *text;
	switch (index) {
		case 3:
			text = @"Banner and sound";
			break;
		case 2:
			text = @"Banner";
			break;
		case 1:
			text = @"None";
			break;
		default:
			text = @"Disabled";
			break;
	}
	return text;
}

- (IBAction)notificationChangedAction:(UISegmentedControl *)sender {
	self.notificationTypeLabel.text = [self textForNotificationIndex:sender.selectedSegmentIndex];
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
			case 3:
				type = NotificationBannerSound;
				break;
			case 2:
				type = NotificationBanner;
				break;
			case 1:
				type = NotificationNone;
				break;
			default:
				type = NotificationDisabled;
				break;
		}
		if (self.topic)
			[connection updateTopicForAccount:self.account name:topicName type:type
								 filterScript:self.topic.filterScriptEdited];
		else
			[connection addTopicForAccount:self.account name:topicName type:type
							  filterScript:@""];
	}
}

- (void)goBack:(id)sender {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Script has not been saved" message:@"Discard changes?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *discardAction = [UIAlertAction actionWithTitle:@"Discard" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {[self.navigationController popViewControllerAnimated:YES];}];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
	[alert addAction:discardAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getResult:) name:@"ServerUpdateNotification" object:nil];
	self.scriptModifiedLabel.hidden = YES;
	if (self.topic) {
		self.subscribeBarButtonItem.enabled = YES;
		self.topicTitleLabel.text = @"Topic:";
		self.topicTextField.text = self.topic.name;
		self.topicTextField.enabled = NO;
		switch (self.topic.type) {
			case NotificationBannerSound:
				self.notificationTypeLabel.text = [self textForNotificationIndex:3];
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 3;
				break;
			case NotificationBanner:
				self.notificationTypeLabel.text = [self textForNotificationIndex:2];
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 2;
				break;
			case NotificationNone:
				self.notificationTypeLabel.text = [self textForNotificationIndex:1];
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 1;
				break;
			default:
				self.notificationTypeLabel.text = [self textForNotificationIndex:0];
				self.notificationTypeSegmentedControl.selectedSegmentIndex = 0;
				break;
		}
	} else {
		self.subscribeBarButtonItem.enabled = NO;
		self.topicTitleLabel.text = @"Subscribe to topic:";
		self.notificationTypeSegmentedControl.selectedSegmentIndex = 2;
		self.notificationTypeLabel.text = @"Banner";
	}
	self.filterButton.hidden = YES;
	if (self.topic) {
		self.filterButton.hidden = NO;
		if (self.topic.filterScript.length)
			[self.filterButton setTitle:@"Edit" forState:UIControlStateNormal];
		else
			[self.filterButton setTitle:@"Add" forState:UIControlStateNormal];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (self.topic) {
		if (![self.topic.filterScriptEdited isEqualToString:self.topic.filterScript]) {
			self.scriptModifiedLabel.hidden = NO;
			UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
			self.navigationItem.leftBarButtonItem = backButton;
		}
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

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	ScriptViewController *controller = segue.destinationViewController;
	controller.topic = self.topic;
	controller.account = self.account;
}


@end
