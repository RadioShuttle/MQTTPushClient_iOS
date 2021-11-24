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

/* Background */
@property IBOutlet DashCircleViewButton *backgroundColorButton;
@property IBOutlet UIButton *backgroundImageButton;

/* Subscribe */
@property (weak, nonatomic) IBOutlet UITextField *topicSubTextField;
@property IBOutlet UISwitch *provideHistDataSwitch;
@property IBOutlet UIButton *filterSciptButton;
@property IBOutlet UILabel *filterSciptModifiedLabel;

/* Publish */
@property (weak, nonatomic) IBOutlet UITextField *topicPubTextField;
@property (weak, nonatomic) IBOutlet UISwitch *retainSwitch;
@property IBOutlet UISegmentedControl *inputTypeSegmentedCtrl;
@property IBOutlet UIButton *outputSciptButton;
@property IBOutlet UILabel *outputSciptModifiedLabel;

/* Option List */
@property IBOutlet UITableView *optionListTableView;
@property IBOutlet UIButton *optionListEditButton;
@property IBOutlet UIButton *optionListAddButton;

/* Paramters and HTML */
@property IBOutlet UITextField *paramter1TextField;
@property IBOutlet UITextField *paramter2TextField;
@property IBOutlet UITextField *paramter3TextField;
@property IBOutlet UITextView *htmlTextView;

/* misc */
@property UIColor *labelDefaultColor;

@end
