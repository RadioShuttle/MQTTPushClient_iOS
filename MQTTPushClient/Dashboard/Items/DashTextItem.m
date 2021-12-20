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

-(id)copyWithZone:(NSZone *)zone {
	DashTextItem *clone = [super copyWithZone:zone];
	clone.inputtype = self.inputtype;
	return clone;
}

- (BOOL)isEqual:(id)other {
	return [super isEqual:other] && self.inputtype == ((DashTextItem *) other).inputtype;
}

- (NSDictionary *)toJSONObject {
	NSMutableDictionary *o = (NSMutableDictionary *) [super toJSONObject];
	[o setObject:@"text" forKey:@"type"];
	[o setObject:[NSNumber numberWithInt:self.inputtype] forKey:@"inputtype"];

	return o;
}

@end
