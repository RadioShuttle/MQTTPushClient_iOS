/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashCustomItem.h"
#import "NSDictionary+HelSafeAccessors.h"

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
	clone.parameter = [self.parameter copy];
	clone.html = self.html;
	
	return clone;
}


@end
