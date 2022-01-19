/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashItem.h"

@interface DashSliderItem : DashItem

@property double range_min;
@property double range_max;
@property int decimal;
@property int64_t progresscolor;
@property BOOL percent;

/* checks if content is a number and within the defined range and sets an error msg */
-(void)validateContent;

+(double) calcProgressInPercent:(double)v min:(double)min max:(double)max;
@end
