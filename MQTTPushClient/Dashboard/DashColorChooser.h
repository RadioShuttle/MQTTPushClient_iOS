/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashEditItemViewController.h"

@interface DashColorChooser : UICollectionViewController

/* button responsible for open color chooser */
@property DashCircleViewButton* srcButton;
/* parent controller */
@property DashEditItemViewController *parentCtrl;

@property UIColor *defaultColor;
@property BOOL showClearColor;

@end
