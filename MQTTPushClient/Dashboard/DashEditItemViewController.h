/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItem.h"
#import "DashCircleViewButton.h"
#import "Dashboard.h"
#import "DashOptionListItem.h"

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
@property IBOutlet UIBarButtonItem *moreButtonItem;

/* Progress Bar/Slider */
@property IBOutlet UITextField *rangeLBTextField;
@property IBOutlet UITextField *rangeUBTextField;
@property IBOutlet UITextField *decimalTextField;
@property IBOutlet UISwitch *displayInPercentSwitch;
@property IBOutlet DashCircleViewButton *progressColorButton;

/* Button/Switch */
@property IBOutlet UITextField *switchOnValueTextField;
@property IBOutlet DashCircleViewButton *switchOnColorButton;
@property IBOutlet DashCircleViewButton *switchOnBackgroundColorButton;
@property IBOutlet UIButton *switchOnImageButton;
@property IBOutlet UITextField *switchOffValueTextField;
@property IBOutlet DashCircleViewButton *switchOffColorButton;
@property IBOutlet DashCircleViewButton *switchOffBackgroundColorButton;
@property IBOutlet UIButton *switchOffImageButton;

- (IBAction) unwindEditOptionListItem:(UIStoryboardSegue*)unwindSegue;
- (void)onOptionListItemUpdated:(Mode)mode item:(DashOptionListItem *)item oldPos:(int)oldPos newPos:(int)newPos;
-(void)onColorChanged:(DashCircleViewButton *)src color:(int64_t)color;

-(void)onFilterScriptContentUpdated:(NSString *)content;
-(void)onOutputScriptContentUpdated:(NSString *)content;

-(void)onImageSelected:(UIButton *)src imageURI:(NSString *)imageURI;

/* returns the dash item with the current input*/
-(DashItem *)getDashItem;

/* misc */
@property UIColor *labelDefaultColor;

@end
