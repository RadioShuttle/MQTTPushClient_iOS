/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashDetailViewController.h"

@interface DashDetailViewController ()

@end

@implementation DashDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)onDashboardUpdate {
	/* will be called, if the dashboard has been updated. In this case the item data and view is no longer valid */
	self.invalid = YES;
	//TODO: display warning
	NSLog(@"DashDetailViewController: Dashboard has been updated");
}

-(void)onNewMessage {
	/* a new message has arrived that matches dashItem.topic_s */
	if (!self.invalid) {
		//TODO: update ui
		NSLog(@"DashDetailViewController: onNewMessage");
	}
}

@end
