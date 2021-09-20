/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionItem.h"
#import "NSDictionary+HelSafeAccessors.h"

@implementation DashOptionItem

- (instancetype)init
{
    return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];

	self.optionList = [NSMutableArray new];

	if (dictObj) {
		NSArray *optionListJSON = [dictObj helArrayForKey:@"optionlist"];
		DashOptionListItem *listItem;
		for(int i = 0; i < [optionListJSON count]; i++) {
			listItem = [[DashOptionListItem alloc]initWithJSON:optionListJSON[i]];
			[(NSMutableArray *) self.optionList addObject:listItem];
		}
	}

	return self;
}

@end
