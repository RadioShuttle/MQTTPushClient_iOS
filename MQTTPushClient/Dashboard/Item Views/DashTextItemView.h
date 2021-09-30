/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItemView.h"

@interface DashTextItemView : DashItemView
@property UILabel *valueLabel;
@property UITextField *inputTextField;
@property UIButton *submitButton;

-(void) showInputElements; // must be called to show input elements in detail view

@end
