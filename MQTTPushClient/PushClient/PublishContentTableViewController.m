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

@property (weak, nonatomic) IBOutlet UILabel *topicLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UISwitch *retainSwitch;



@end

@implementation PublishContentTableViewController

- (IBAction)publishAction:(UIButton *)sender {
	Connection *connection = [[Connection alloc] init];
	[connection publishMessageForAccount:self.account action:self.action];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.topicLabel.text = self.action.topic;
	self.contentLabel.text = self.action.content;
	self.retainSwitch.on = self.action.retainFlag;
}

@end
