/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashDetailViewController.h"
#import "DashTextItem.h"
#import "DashTextItemView.h"
#import "DashCustomItem.h"
#import "DashCustomItemView.h"
#import "DashSwitchItem.h"
#import "DashSwitchItemView.h"
#import "DashSliderItem.h"
#import "DashSliderItemView.h"
#import "Utils.h"

@interface DashDetailViewController ()

@end

@implementation DashDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	// [self hideBarButtonItem:self.errorButton1];
	// self.errorView.layer.zPosition = -1;
	
	//TODO: optimize code when all dash items implemented
	if ([DashTextItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashTextItemView alloc] initWithFrame:self.containerView.bounds];
		[(DashTextItemView *) self.dashItemView showInputElements];

	} else if ([DashCustomItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashCustomItemView alloc] initWithFrame:self.containerView.bounds];
	} else if ([DashSwitchItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashSwitchItemView alloc] initWithFrame:self.containerView.bounds];
	} else if ([DashSliderItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashSliderItemView alloc] initWithFrame:self.containerView.bounds];
	}

	self.dashItemView.detailView = YES;
	[self updateLabel];

	if (self.dashItemView) {
		[self.dashItemView onBind:self.dashItem context:self.dashboard];
		[self.containerView addSubview:self.dashItemView];
		[self.view bringSubviewToFront:self.containerView];
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

/* will be called if custom view (webview) has updated data via javascript */
-(void)onUpdate:(DashCustomItem *)item what:(NSString *)what {
	//TODO
}

/* will be called, if the dashboard has been updated. In this case the item data and view is no longer valid */
-(void)onDashboardUpdate {
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

-(void)updateLabel {
	NSMutableString *label = [NSMutableString new];
	if (![Utils isEmpty:self.dashItem.label]) {
		[label appendString:self.dashItem.label];
	}
	if (self.dashItem.lastMsgTimestamp) {
		[label appendString:@" - "];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		dateFormatter.timeStyle = NSDateFormatterShortStyle;
		[label appendString:[dateFormatter stringFromDate:self.dashItem.lastMsgTimestamp]];
	}
	
	[self.dashItemLabel setText:label];
}

@end
