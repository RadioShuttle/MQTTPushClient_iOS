/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "AppDelegate.h"
#import "ServerSetupTableViewController.h"

@interface ServerSetupTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPortTextField;
@property (weak, nonatomic) IBOutlet UISwitch *mqttSecuritySwitch;
@property (weak, nonatomic) IBOutlet UITextField *mqttUserTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPasswordTextField;
@property Account *server;

@end

@implementation ServerSetupTableViewController

- (void)saveSettings {
	self.server.host = self.addressTextField.text;
	self.server.mqtt.host = self.mqttAddressTextField.text;
	self.server.mqtt.port = [NSNumber numberWithInt:[self.mqttPortTextField.text intValue]];
	self.server.mqtt.secureTransport = self.mqttSecuritySwitch.on;
	self.server.mqtt.user = self.mqttUserTextField.text;
	self.server.mqtt.password = self.mqttPasswordTextField.text;
	if (!self.indexPath)
		[self.serverList addObject:self.server];
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	[appDelegate saveAccounts];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(UIButton *)sender {
	[self saveSettings];
}

- (IBAction)saveButtonAction:(UIButton *)sender {
	[self saveSettings];
}

- (void)updateUI {
	self.addressTextField.text = self.server.host;
	self.mqttAddressTextField.text = self.server.mqtt.host;
	self.mqttPortTextField.text = [NSString stringWithFormat:@"%@", self.server.mqtt.port];
	self.mqttSecuritySwitch.on = self.server.mqtt.secureTransport;
	self.mqttUserTextField.text = self.server.mqtt.user;
	self.mqttPasswordTextField.text = self.server.mqtt.password;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.indexPath)
		self.server = self.serverList[self.indexPath.row];
	else
		self.server = [[Account alloc] init];
	[self updateUI];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
