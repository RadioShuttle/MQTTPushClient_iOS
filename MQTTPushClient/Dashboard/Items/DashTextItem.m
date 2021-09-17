/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashTextItem.h"
#import "NSDictionary+HelSafeAccessors.h"

@implementation DashTextItem

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];
	self.inputtype = [[dictObj helNumberForKey:@"input_type"] intValue];
	return self;
}
@end
