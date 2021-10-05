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
@end
