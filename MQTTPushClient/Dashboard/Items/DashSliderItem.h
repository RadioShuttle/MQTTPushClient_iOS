/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DashSliderItem : DashItem

@property double range_min;
@property double range_max;
@property int decimal;
@property uint64_t progresscolor;
@property BOOL percent;

+(double) calcProgressInPercent:(double)v min:(double)min max:(double)max;
@end

NS_ASSUME_NONNULL_END
