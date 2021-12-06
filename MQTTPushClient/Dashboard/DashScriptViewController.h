/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

#import "Topic.h"
#import "Account.h"
#import "DashItem.h"
#import "Dashboard.h"
#import "DashEditItemViewController.h"

@interface DashScriptViewController : UITableViewController

/* args */
@property BOOL filterScriptMode;
@property DashEditItemViewController *parentCtrl;


@end
