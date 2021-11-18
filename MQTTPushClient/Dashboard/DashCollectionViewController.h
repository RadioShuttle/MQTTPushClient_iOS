/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "Account.h"
#import "Dashboard.h"
#import "Connection.h"
#import "DashCollectionFlowLayout.h"
#import "DashDetailViewController.h"
#import "DashPublishController.h"
#import "DashGroupItemViewCell.h"

@interface DashCollectionViewController : UICollectionViewController <DashPublishController, DashGroupSelectionHandler>

@property Account *account;
@property Dashboard *dashboard;
@property Connection *connection;
@property NSDictionary *preferences;

@property DashDetailViewController *activeDetailView;
@property NSOperationQueue *jsOperationQueue;
@property NSMutableArray<NSInvocationOperation *> *jsTaskQueue;
@property uint32_t publishReqIDCounter;
@property BOOL editMode;
/* selected items */
@property NSMutableArray *selectedItems;

@property (weak, nonatomic) IBOutlet DashCollectionFlowLayout *dashCollectionFlowLayout;
@property NSTimer* timer;
@property (weak, nonatomic) IBOutlet UILabel *statusBarLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *listViewButtonItem;

@end
