/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "AppDelegate.h"
#import "MessageQueuingTelemetryTransport.h"
#import "Connection.h"
#import "ServerSetupTableViewController.h"

@interface ServerSetupTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPortTextField;
@property (weak, nonatomic) IBOutlet UISwitch *mqttSecuritySwitch;
@property (weak, nonatomic) IBOutlet UITextField *mqttUserTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPasswordTextField;
@property Account *account;

@end

@implementation ServerSetupTableViewController

- (void)saveSettings {
	self.account.host = self.addressTextField.text;
	self.account.mqtt.host = self.mqttAddressTextField.text;
	self.account.mqtt.port = [NSNumber numberWithInt:[self.mqttPortTextField.text intValue]];
	self.account.mqtt.secureTransport = self.mqttSecuritySwitch.on;
	self.account.mqtt.user = self.mqttUserTextField.text;
	self.account.mqtt.password = self.mqttPasswordTextField.text;
	if (!self.indexPath)
		[self.accountList addObject:self.account];
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	[appDelegate saveAccounts];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(UIButton *)sender {
	Connection *connection = [[Connection alloc] init];
	[connection getFcmDataForAccount:self.account];
	[self saveSettings];
}

- (IBAction)saveButtonAction:(UIButton *)sender {
	Connection *connection = [[Connection alloc] init];
	[connection getFcmDataForAccount:self.account];
	[self saveSettings];
}

- (IBAction)setSecurity:(UISwitch *)sender {
	if (sender.on)
		self.mqttPortTextField.text = [NSString stringWithFormat:@"%d", MQTT_SECURE_PORT];
	else
		self.mqttPortTextField.text = [NSString stringWithFormat:@"%d", MQTT_DEFAULT_PORT];
}

- (void)updateUI {
	self.addressTextField.text = self.account.host;
	self.mqttAddressTextField.text = self.account.mqtt.host;
	self.mqttPortTextField.text = [NSString stringWithFormat:@"%@", self.account.mqtt.port];
	self.mqttSecuritySwitch.on = self.account.mqtt.secureTransport;
	self.mqttUserTextField.text = self.account.mqtt.user;
	self.mqttPasswordTextField.text = self.account.mqtt.password;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.indexPath)
		self.account = self.accountList[self.indexPath.row];
	else
		self.account = [[Account alloc] init];
	[self updateUI];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
