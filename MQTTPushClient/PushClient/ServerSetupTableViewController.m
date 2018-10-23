/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "AppDelegate.h"
#import "ServerSetupTableViewController.h"
#import "Connection.h"

@interface ServerSetupTableViewController () {
    BOOL hostValid;
    BOOL mqttHostValid;
    BOOL mqttUserValid;
}

@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttAddressTextField;
@property (weak, nonatomic) IBOutlet UISwitch *mqttSecuritySwitch;
@property (weak, nonatomic) IBOutlet UITextField *mqttUserTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPasswordTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIAlertController *progress;

@end

// Some string that is very unlikely to be chosen as actual password:
static NSString *kUnchangedPasswd = @"¥µÿ®©¶";

@implementation ServerSetupTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	BOOL newAccount = self.indexPath == nil;
	self.addressTextField.enabled = newAccount;
	self.mqttAddressTextField.enabled = newAccount;
	self.mqttSecuritySwitch.enabled = newAccount;
	self.mqttUserTextField.enabled = newAccount;

	if (newAccount) {
		self.navigationItem.title = @"New Account";
		self.addressTextField.text = @"";
		self.mqttAddressTextField.text = @"";
		self.mqttSecuritySwitch.on = NO;
		self.mqttUserTextField.text = @"";
		self.mqttPasswordTextField.text = @"";
	} else {
		Account *account = self.accountList[self.indexPath.row];
		self.navigationItem.title = account.mqttHost;
		self.addressTextField.text = account.host;
		self.mqttAddressTextField.text = account.mqttHost;
		self.mqttSecuritySwitch.on = account.mqttSecureTransport;
		self.mqttUserTextField.text = account.mqttUser;
		self.mqttPasswordTextField.text = (account.mqttPassword == nil) ? @"" : kUnchangedPasswd;
	}
    
    [self validateFields:nil]; // Initial validation
    self.saveButton.enabled = NO; // Enabled on first change, if all fields are valid.
}

- (IBAction)saveAction:(UIButton *)sender {
    self.saveButton.enabled = NO;
    self.tableView.userInteractionEnabled = NO;
    [self resignFirstResponder];
    [self saveSettings];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    if (textField == self.addressTextField) {
        [self.mqttAddressTextField becomeFirstResponder];
    } else if (textField == self.mqttAddressTextField) {
            [self.mqttUserTextField becomeFirstResponder];
    } else if (textField == self.mqttUserTextField) {
        [self.mqttPasswordTextField becomeFirstResponder];
    }
	return YES;
}

- (IBAction)validateFields:(id)sender {
	if (sender == nil || sender == self.addressTextField) {
		self->hostValid = self.addressTextField.text.length > 0;
	}
	if (sender == nil || sender == self.mqttAddressTextField) {
		self->mqttHostValid = self.mqttAddressTextField.text.length > 0;
	}
	if (sender == nil || sender == self.mqttUserTextField) {
		self->mqttUserValid = self.mqttUserTextField.text.length > 0;
	}
	if (sender != nil) {
		self.saveButton.enabled = (self->hostValid && self->mqttHostValid &&
								   self->mqttUserValid);
	}
}

#pragma mark - Save settings

- (void)saveSettings {
	Account *account;
	NSString *mqttPassword = self.mqttPasswordTextField.text;
	if (mqttPassword == nil) {
		mqttPassword = @"";
	}
	if (self.indexPath == nil) {
		account = [Account accountWithHost:self.addressTextField.text
									   mqttHost:self.mqttAddressTextField.text
							mqttSecureTransport:self.mqttSecuritySwitch.on
									   mqttUser:self.mqttUserTextField.text
										   uuid:nil];
	} else {
		if ([mqttPassword isEqualToString:kUnchangedPasswd]) {
			[self saveSuccess];
			return;
		}
		account = self.accountList[self.indexPath.row];
	}
	
	self.progress = [UIAlertController alertControllerWithTitle:account.host
														message:@"Verifying data ..."
												 preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction
								   actionWithTitle:@"Cancel"
								   style:UIAlertActionStyleCancel
								   handler:^(UIAlertAction *action) {
									   self.progress = nil;
									   [self saveCanceled];
								   }];
	[self.progress addAction:cancelAction];
	[self presentViewController:self.progress animated:YES completion:nil];
	
	dispatch_async(dispatch_queue_create("de.helios.verifyaccount", DISPATCH_QUEUE_SERIAL), ^{
		Connection *connection = [[Connection alloc] init];
		Cmd *cmd = [connection login:account withMqttPassword:mqttPassword];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (cmd.rawCmd.error != nil) {
				[self saveFailed:@"Login failed" message:cmd.rawCmd.error.localizedDescription];
			} else if (cmd.rawCmd.rc == RC_NOT_AUTHORIZED) {
				[self saveFailed:@"Login failed" message:@"Wrong user name or password"];
			} else if (cmd.rawCmd.rc != RC_OK) {
				[self saveFailed:@"Login failed" message:nil];
			} else if (self.indexPath == nil) {
				// New account
				if (![account configure]) {
					[self saveFailed:NULL message:@"Could not create account"];
				} else {
					[self.accountList addAccount:account];
					[self.accountList save];
					account.mqttPassword = mqttPassword;
					[self saveSuccess];
				}
			} else {
				// Existing account
				if (mqttPassword != kUnchangedPasswd) {
					account.mqttPassword = mqttPassword;
				}
				[self saveSuccess];
			}
		});
	});
}

/*
 * Account data successfully updated. Dismiss all modal dialogs
 * and leave this dialog (return to account list).
 */
- (void)saveSuccess {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self];
	if (self.progress) {
		[self.progress dismissViewControllerAnimated:YES completion: ^{
			[self.navigationController popViewControllerAnimated:YES];
		}];
		self.progress = nil;
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

/*
 * Could not update account data (server not reached, wrong password, ...).
 * Dismiss progress window, show error message, and continue editing.
 */
-(void)saveFailed:(NSString *)title message:(NSString *)message {
	UIAlertController *alert = [UIAlertController
								alertControllerWithTitle:title
								message:message
								preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
													   style:UIAlertActionStyleDefault
													 handler:^(UIAlertAction *action) {
														 self.saveButton.enabled = YES;
														 self.tableView.userInteractionEnabled = YES;
													 }];
	[alert addAction:okAction];
	
	if (self.progress) {
		[self.progress dismissViewControllerAnimated:YES completion: ^{
			[self presentViewController:alert animated:YES completion:nil];
		}];
		self.progress = nil;
	} else {
		[self presentViewController:alert animated:YES completion:nil];
	}
}

/*
 * User canceled the operation. Dismiss progess window, cancel server
 * connection, and continue editing account data.
 */
-(void)saveCanceled {
	[self.progress dismissViewControllerAnimated:YES completion: nil];
	self.progress = nil;
	self.saveButton.enabled = YES;
	self.tableView.userInteractionEnabled = YES;
}

@end
