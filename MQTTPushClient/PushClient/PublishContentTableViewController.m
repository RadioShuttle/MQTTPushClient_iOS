/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Action.h"
#import "Account.h"
#import "Connection.h"
#import "PublishContentTableViewController.h"

@interface PublishContentTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *topicLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UISwitch *retainSwitch;

@end

@implementation PublishContentTableViewController

- (IBAction)publishAction:(UIBarButtonItem *)sender {
	self.action.retainFlag = self.retainSwitch.on;
	Connection *connection = [[Connection alloc] init];
	[connection publishMessageForAccount:self.account action:self.action];
	[self.navigationController popToViewController:self.messageList animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.nameLabel.text = self.action.name;
	self.topicLabel.text = self.action.topic;
	self.contentLabel.text = self.action.content;
	self.retainSwitch.on = self.action.retainFlag;
}

@end
