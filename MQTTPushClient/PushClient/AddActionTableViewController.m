/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "Connection.h"
#import "Action.h"
#import "AddActionTableViewController.h"

@interface AddActionTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *topicTextField;
@property (weak, nonatomic) IBOutlet UITextField *contentTextField;
@property (weak, nonatomic) IBOutlet UISwitch *retainSwitch;

@end

@implementation AddActionTableViewController

- (void)getResult:(NSNotification *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)validateFields:(id)sender {
	self.saveBarButtonItem.enabled = self.nameTextField.text.length > 0 && self.topicTextField.text.length > 0 && self.contentTextField.text.length > 0;
}

- (IBAction)saveAction:(UIBarButtonItem *)sender {
	Connection *connection = [[Connection alloc] init];
	if (self.action) {
		[connection updateActionForAccount:self.account action:self.action name:self.nameTextField.text];
	} else {
		Action *action = [[Action alloc] init];
		action.name = self.nameTextField.text;
		action.topic = self.topicTextField.text;
		action.content = self.contentTextField.text;
		action.retainFlag = self.retainSwitch.on;
		[connection addActionForAccount:self.account action:action];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getResult:) name:@"ServerUpdateNotification" object:nil];
	self.saveBarButtonItem.enabled = NO;
	if (self.action) {
		self.nameTextField.text = self.action.name;
		self.topicTextField.text = self.action.topic;
		self.contentTextField.text = self.action.content;
		self.retainSwitch.on = self.action.retainFlag;
		self.topicTextField.enabled = NO;
		self.contentTextField.enabled = NO;
		self.retainSwitch.enabled = NO;
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
