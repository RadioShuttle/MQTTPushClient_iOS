/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "Account.h"
#import "Dashboard.h"

NS_ASSUME_NONNULL_BEGIN

@interface DashCollectionViewController : UICollectionViewController

@property Account *account;
@property Dashboard *dashboard;
@property (weak, nonatomic) IBOutlet UILabel *statusBarLabel;

@end

NS_ASSUME_NONNULL_END
