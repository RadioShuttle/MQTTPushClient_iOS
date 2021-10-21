/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>
#import "DashItemView.h"

@interface DashSliderItemView : DashItemView
@property UILabel *valueLabel;
@property UIProgressView *progressView;
@property UISlider *sliderCtrl;

/* holds the current value (last messages's value) */
@property NSString *formattedValue;
/* holds the current value set with the slider */
@property NSString *formattedSliderValue;
@property NSNumberFormatter *formatter;

/* similar to item.percent */
@property BOOL displayPC;
/* true, when user is currently using the slider (touch event and not released) */
@property BOOL sliderPressed;
@end
