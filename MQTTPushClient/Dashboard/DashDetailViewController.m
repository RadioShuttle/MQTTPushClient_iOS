/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashDetailViewController.h"
#import "DashTextItem.h"
#import "DashTextItemView.h"

@interface DashDetailViewController ()

@end

@implementation DashDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	// [self hideBarButtonItem:self.errorButton1];
	// self.errorView.layer.zPosition = -1;
	
	if ([DashTextItem class] == [self.dashItem class]) {
		DashTextItemView *view = [[DashTextItemView alloc] initWithFrame:self.containerView.bounds];
		[view onBind:self.dashItem context:self.dashboard];
		[view showInputElements];

		[self.view bringSubviewToFront:self.containerView];
		
		[self.containerView addSubview:view];
		self.dashItemView = view;
	}
	
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
		/* update view */
		[self.dashItemView onBind:self.dashItem context:self.dashboard];
	}
}

-(void) hideBarButtonItem :(UIBarButtonItem *)myButton {
	// Get the reference to the current toolbar buttons
	NSMutableArray *navBarBtns = [self.toolbarNavigationItem.rightBarButtonItems mutableCopy];
	
	// This is how you remove the button from the toolbar and animate it
	[navBarBtns removeObject:myButton];
	[self.toolbarNavigationItem setRightBarButtonItems:navBarBtns animated:NO];
}


-(void) showBarButtonItem :(UIBarButtonItem *)myButton {
	// Get the reference to the current toolbar buttons
	NSMutableArray *navBarBtns = [self.toolbarNavigationItem.rightBarButtonItems mutableCopy];
	
	// This is how you add the button to the toolbar and animate it
	if (![navBarBtns containsObject:myButton]) {
		[navBarBtns addObject:myButton];
		[self.toolbarNavigationItem setRightBarButtonItems:navBarBtns animated:NO];
	}
}

@end
