/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "Dashboard.h"
#import "DashItemView.h"
#import "DashCustomItemView.h"

@interface DashDetailViewController : UIViewController <DashCustomViewContainer>

@property DashItem *dashItem;
@property Dashboard *dashboard;

@property BOOL invalid;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *errorButton1;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *errorButton2;
@property (strong, nonatomic) IBOutlet UINavigationItem *toolbarNavigationItem;
@property (weak, nonatomic) IBOutlet UIView *errorView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property DashItemView *dashItemView;
@property (weak, nonatomic) IBOutlet UILabel *dashItemLabel;

/* will be called, if the dashboard has been updated. In this case this view controller is no longer valid */
-(void)onDashboardUpdate;
/* will be called, if a new message has arrived that matches dashItem.topic_s */
-(void)onNewMessage;

@end
