/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashSliderItem.h"
#import "DashConsts.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "DashUtils.h"

@implementation DashSliderItem

- (instancetype)init
{
    return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];
	
	self.progresscolor = DASH_COLOR_OS_DEFAULT;
	self.range_max = 100.0f;
	
	if (dictObj) {
		NSNumber *numVal;
		
		numVal = [dictObj helNumberForKey:@"progresscolor"];
		if (numVal) {
			self.progresscolor = [numVal unsignedLongLongValue];
		}
		numVal = [dictObj helNumberForKey:@"range_max"];
		if (numVal) {
			self.range_max = [numVal unsignedLongLongValue];
		}

		self.range_min = [[dictObj helNumberForKey:@"range_min"] doubleValue];
		self.decimal = [[dictObj helNumberForKey:@"decimal"] intValue];
		self.percent = [[dictObj helNumberForKey:@"percent"] boolValue];
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

-(id)copyWithZone:(NSZone *)zone {
	DashSliderItem *clone = [super copyWithZone:zone];
	clone.range_min = self.range_min;
	clone.range_max = self.range_max;
	clone.decimal = self.decimal;
	clone.progresscolor = self.progresscolor;
	clone.percent = self.percent;
	return clone;
}

- (BOOL)isEqual:(id)other {
	BOOL eq = [super isEqual:other];
	if (eq) {
		DashSliderItem *o = (DashSliderItem *) other;
		
		eq = self.range_min == o.range_min && self.range_max == self.range_max && self.decimal == o.decimal && [DashUtils cmpColor:self.progresscolor color:o.progresscolor] && self.percent == o.percent;
	}
	return eq;
}

@end
