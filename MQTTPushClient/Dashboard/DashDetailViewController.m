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
#import "DashOptionItem.h"
#import "DashOptionItemView.h"
#import "Utils.h"
#import "DashConsts.h"

@interface DashDetailViewController ()

@end

@implementation DashDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	if ([DashTextItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashTextItemView alloc] initDetailViewWithFrame:self.containerView.bounds];
	} else if ([DashCustomItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashCustomItemView alloc] initDetailViewWithFrame:self.containerView.bounds];
		((DashCustomItemView *) self.dashItemView).container = self;
	} else if ([DashSwitchItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashSwitchItemView alloc] initDetailViewWithFrame:self.containerView.bounds];
	} else if ([DashSliderItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashSliderItemView alloc] initDetailViewWithFrame:self.containerView.bounds];
	} else if ([DashOptionItem class] == [self.dashItem class]) {
		self.dashItemView = [[DashOptionItemView alloc] initDetailViewWithFrame:self.containerView.bounds];
	}

	[self.errorView setBackgroundColor:UIColorFromRGB(DASH_DEFAULT_CELL_COLOR)]; //TODO: dark mode
	self.errorButton1.action = @selector(onErrorButton1Clicked);
	self.errorButton2.action = @selector(onErrorButton2Clicked);

	[self updateLabel];
	[self updateErrorButtons];

	if (self.dashItemView) {
		self.dashItemView.controller = self;
		[self.dashItemView onBind:self.dashItem context:self.dashboard];
		[self.containerView addSubview:self.dashItemView];
		[self.view bringSubviewToFront:self.containerView];
	}
	
}
-(void)viewDidLayoutSubviews {
	if ([DashOptionItem class] == [self.dashItem class]) {
		DashOptionItemView *optView = (DashOptionItemView *) self.dashItemView;
		DashOptionItem *optItem = (DashOptionItem *) self.dashItem;
		if (![Utils isEmpty:self.dashItem.content]) {
			for(int i = 0; i < optItem.optionList.count; i++) {
				if ([self.dashItem.content isEqualToString:optItem.optionList[i].value]) {
					NSIndexPath *idx = [NSIndexPath indexPathForRow:i inSection:0];
					[optView.optionListTableView scrollToRowAtIndexPath:idx atScrollPosition:UITableViewScrollPositionTop animated:NO];
					break;
				}
			}
		}
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
	if ([what isEqualToString:@"error"]) {
		[self updateErrorButtons];
	}
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
		[self updateLabel];
		[self updateErrorButtons];
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
		if ([[NSCalendar currentCalendar] isDateInToday:self.dashItem.lastMsgTimestamp]) {
			dateFormatter.dateStyle = NSDateFormatterNoStyle;
		} else {
			dateFormatter.dateStyle = NSDateFormatterShortStyle;
		}
		dateFormatter.timeStyle = NSDateFormatterShortStyle;
		[label appendString:[dateFormatter stringFromDate:self.dashItem.lastMsgTimestamp]];
	}
	
	[self.dashItemLabel setText:label];
}

-(void)updateErrorButtons {
	BOOL error = ![Utils isEmpty:self.dashItem.error1];
	if (error) {
		[self showBarButtonItem:self.errorButton1];
	} else {
		[self hideBarButtonItem:self.errorButton1];
	}
	error = ![Utils isEmpty:self.dashItem.error2];
	if (error) {
		[self showBarButtonItem:self.errorButton2];
	} else {
		[self hideBarButtonItem:self.errorButton2];
	}
}

-(void)onErrorButton1Clicked {
	UIView *v;
	if (self.currentView == 1) {
		self.currentView = 0;
		v = self.containerView;
	} else { // if (self.currentView in (0,2))
		self.currentView = 1;
		[self.errorLabel setText:self.dashItem.error1];
		v = self.errorView;
	}
	[self.view bringSubviewToFront:v];
}

-(void)onErrorButton2Clicked {
	UIView *v;
	if (self.currentView == 2) {
		self.currentView = 0;
		v = self.containerView;
	} else { // if (self.currentView in (0, 1))
		self.currentView = 2;
		[self.errorLabel setText:self.dashItem.error2];
		v = self.errorView;
	}
	[self.view bringSubviewToFront:v];

}

- (DashItem *)getItem {
	return self.dashItem;
}

-(void)performSend:(NSData *)data queue:(BOOL)queue {
	[self performSend:self.dashItem.topic_p data:data retain:self.dashItem.retain_ queue:queue];
}

-(void) performSend:(NSString *)topic data:(NSData *)data retain:(BOOL)retain queue:(BOOL)queue {
	NSLog(@"publish for item %@, topic: %@, retain: %i, payload: %@", self.dashItem.label, topic, retain, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	if (self.currentPublishID > 0) {
		if (!queue) {
			//TODO: display: Please wait until current request has been finished.
		} else {
			self.queue = data;
		}
	} else {
		//TODO: show progess bar
		[self.controller publish:topic payload:data retain:retain item:self.dashItem];
		
	}
		
}

@end
