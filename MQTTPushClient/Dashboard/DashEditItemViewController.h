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

/* the data before editing started */
@property DashItem *orgItem;

/* General section */
@property (weak, nonatomic) IBOutlet UITextField *labelTextField;
@property IBOutlet UILabel *groupLabel;
@property IBOutlet UIButton *groupDropDownButon;
@property int selGroupIdx;
@property IBOutlet UILabel *posLabel;
@property IBOutlet UIButton *posDropDownButton;
@property int selPosIdx;
@property IBOutlet DashCircleViewButton *textColorButton;
@property IBOutlet UISegmentedControl *textSizeSegmentedCtrl;

/* background */
@property IBOutlet DashCircleViewButton *backgroundColorButton;
@property IBOutlet UIButton *backgroundImageButton;

/* subscribe */
@property (weak, nonatomic) IBOutlet UITextField *topicSubTextField;
@property IBOutlet UIButton *filterSciptButton;
@property IBOutlet UILabel *filterSciptModifiedLabel;

/* publish */
@property (weak, nonatomic) IBOutlet UITextField *topicPubTextField;
@property (weak, nonatomic) IBOutlet UISwitch *retainSwitch;
@property IBOutlet UISegmentedControl *inputTypeSegmentedCtrl;
@property IBOutlet UIButton *outputSciptButton;
@property IBOutlet UILabel *outputSciptModifiedLabel;

/* misc */
@property UIColor *labelDefaultColor;

@end
