/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItemView.h"
#import "DashTextItem.h"

@interface DashTextItemView : DashItemView <UITextFieldDelegate>
@property UILabel *valueLabel;
@property UITextField *inputTextField;
@property UIButton *submitButton;
@property UIStackView *inputStackView;

/* once the user entered an input value, the textFieldDefaultValue will no longer set (via onbind) */
@property BOOL defValueDisabled;
@end
