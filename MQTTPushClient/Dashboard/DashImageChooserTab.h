/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "Dashboard.h"
#import "DashEditItemViewController.h"

@interface DashImageChooserTab : UICollectionViewController <UICollectionViewDataSourcePrefetching>
@property UIViewController *editor; //TODO: consider using protocol
/* image button responsible for open image chooser */
@property UIButton *sourceButton;
@property Dashboard *context;
@end
