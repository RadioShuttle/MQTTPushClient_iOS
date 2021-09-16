/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DashSliderItemView : UIView
@property UILabel *valueLabel;
@property UIProgressView *progressView;
@property UISlider *sliderCtrl;
@end

NS_ASSUME_NONNULL_END
