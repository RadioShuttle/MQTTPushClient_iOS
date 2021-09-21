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

@interface DashCollectionViewController : UICollectionViewController

@property Account *account;
@property Dashboard *dashboard;
@property Connection *connection;
@property (weak, nonatomic) IBOutlet DashCollectionFlowLayout *dashCollectionFlowLayout;
@property NSTimer* timer;
@property (weak, nonatomic) IBOutlet UILabel *statusBarLabel;

@end
