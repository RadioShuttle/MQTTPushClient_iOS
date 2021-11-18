/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "DashCircleViewButton.h"
#import "Dashboard.h"

@interface DashEditItemViewController : UITableViewController

typedef enum {Add, Edit} Mode;

/* arguments passed by caller */
@property Mode mode;
@property DashItem *item;
@property Dashboard *dashboard;

/* General section */
@property (weak, nonatomic) IBOutlet UITextField *labelTextField;
@property IBOutlet UILabel *groupLabel;
@property IBOutlet UIButton *groupDropDownButon;
@property int selGroupIdx;
@property IBOutlet UILabel *posLabel;
@property IBOutlet UIButton *posDropDownButton;
@property int selPosIdx;
@property IBOutlet DashCircleViewButton *textColorButton;
@property IBOutlet UILabel *textSizeLabel;
@property IBOutlet UIButton *textSizeDropDownButton;
@property IBOutlet DashCircleViewButton *backgroundColorButton;
@property IBOutlet UIButton *backgroundImageButton;

@end
