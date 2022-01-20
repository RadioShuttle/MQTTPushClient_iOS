/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashEditItemViewController.h"
#import "DashOptionListItem.h"

@interface DashEditOptionViewController : UITableViewController
@property Mode mode;
@property DashOptionListItem *item;
@property DashOptionListItem *editItem;
@property int pos;
@property int itemCount;
@property DashEditItemViewController *parentController;

@property IBOutlet UITextField *valueTextField;
@property IBOutlet UITextField *labelTextField;
@property IBOutlet UIButton *imageButton;
@property IBOutlet UILabel *imageErrLabel;
@property IBOutlet UILabel *posLabel;
@property IBOutlet UIButton *posDropDownButton;
@property int selPosIdx;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

-(void)onImageSelected:(NSString *)imageURI;

@end
