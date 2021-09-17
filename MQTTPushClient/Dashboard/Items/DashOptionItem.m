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
    self = [super init];
    if (self) {
        _optionList = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super initWithJSON:dictObj];
	
	NSArray *optionListJSON = [dictObj helArrayForKey:@"optionlist"];
	DashOptionListItem *listItem;
	for(int i = 0; i < [optionListJSON count]; i++) {
		listItem = [[DashOptionListItem alloc]initWithJSON:optionListJSON[i]];
		[self.optionList addObject:listItem];
	}

	return self;
}

@end
