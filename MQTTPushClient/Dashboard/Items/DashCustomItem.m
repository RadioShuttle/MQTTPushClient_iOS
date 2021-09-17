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
	self = [super init];
	if (self) {
		_parameter = [NSMutableArray new];
	}
	return self;
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [self init];

	self.html = [dictObj helStringForKey:@"html"];

	NSArray *parameterListJSON = [dictObj helArrayForKey:@"parameter"];
	NSString *listItem;
	for(int i = 0; i < [parameterListJSON count]; i++) {
		listItem = parameterListJSON[i];
		if (listItem) {
			[self.parameter addObject:listItem];
		}
	}
	return self;
}

@end
