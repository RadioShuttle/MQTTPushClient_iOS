/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItem.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"


@implementation DashSliderItem

- (instancetype)init
{
    return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];
	
	_progresscolor = DASH_COLOR_OS_DEFAULT;
	_range_max = 100.0f;
	_range_min = 0.0f;
	
	if (dictObj) {
		self.range_min = [[dictObj helNumberForKey:@"range_min"] doubleValue];
		self.range_max = [[dictObj helNumberForKey:@"range_max"] doubleValue];
		self.decimal = [[dictObj helNumberForKey:@"decimal"] intValue];
		self.percent = [[dictObj helNumberForKey:@"percent"] boolValue];
		self.progresscolor = [[dictObj helNumberForKey:@"progresscolor"] boolValue];
	}
	return self;
}

+(double)calcProgressInPercent:(double)v min:(double)min max:(double)max {
    if (min < max) {
        return 100.0f / (max - min) * (v - min);
    } else {
        return 0.0f;
    }
}

@end
