/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItem.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Utils.h"

@implementation DashCustomItem

- (instancetype)init
{
	return [self initWithJSON:nil];;
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];

	self.parameter = [NSMutableArray new];
	self.html = [dictObj helStringForKey:@"html"];
	
	if (dictObj) {
		NSArray *parameterListJSON = [dictObj helArrayForKey:@"parameter"];
		if (parameterListJSON) {
			self.parameter = parameterListJSON;
		}
	}

	return self;
}

-(id)copyWithZone:(NSZone *)zone {
	DashCustomItem *clone = [super copyWithZone:zone];
	clone.parameter = [self.parameter mutableCopy];
	clone.html = self.html;
	
	return clone;
}

- (BOOL)isEqual:(id)other {
	BOOL eq = [super isEqual:other];
	if (eq) {
		DashCustomItem *o = (DashCustomItem *) other;
		int count = (int) MAX(self.parameter.count, o.parameter.count);
		NSString *s1, *s2;
		for(int i = 0; i < count; i++) {
			s1 = i < self.parameter.count ? self.parameter[i] : nil;
			s2 = i < o.parameter.count ? o.parameter[i] : nil;
			if (![Utils areEqual:s1 s2:s2]) {
				eq = NO;
				break;
			}
		}
		eq = eq && [Utils areEqual:self.html s2:o.html];
	}
	return eq;
}

- (NSDictionary *)toJSONObject {
	NSMutableDictionary *o = (NSMutableDictionary *) [super toJSONObject];
	[o setObject:@"custom" forKey:@"type"];
	[o setObject:self.html ? self.html : @"" forKey:@"html"];
	[o setObject:[self.parameter copy] forKey:@"parameter"];	
	return o;
}

@end
