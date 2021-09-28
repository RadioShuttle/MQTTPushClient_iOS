/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"

@interface DashDetailViewController : UIViewController

@property DashItem *dashItem;

@property BOOL invalid;

/* will be called, if the dashboard has been updated. In this case this view controller is no longer valid */
-(void)onDashboardUpdate;
/* will be called, if a new message has arrived that matches dashItem.topic_s */
-(void)onNewMessage;

@end
