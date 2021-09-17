//
//  DashSliderItem.h
//  BigApp
//
//  Created by Adalbert Winkler on 05.08.21.
//  Copyright © 2021 Adalbert Winkler. All rights reserved.
//

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
