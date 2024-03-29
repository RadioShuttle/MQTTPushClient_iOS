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

-(id)copyWithZone:(NSZone *)zone {
	DashOptionItem *clone = [super copyWithZone:zone];
	clone.optionList = [NSMutableArray new];
	
	DashOptionListItem *clonedItem;
	for(DashOptionListItem *listItem in self.optionList) {
		clonedItem = [listItem copy];
		[(NSMutableArray *) clone.optionList addObject:listItem];
	}
	
	return clone;
}

- (BOOL)isEqual:(id)other {
	BOOL eq = [super isEqual:other];
	if (eq) {
		DashOptionItem *o = (DashOptionItem *) other;
		eq = self.optionList.count == o.optionList.count;
		if (eq) {
			for(int i = 0; i < self.optionList.count; i++) {
				if (![self.optionList[i] isEqual:o.optionList[i]]) {
					eq = NO;
					break;
				}
			}
		}
	}
	return eq;
}

- (NSDictionary *)toJSONObject {
	NSMutableDictionary *o = (NSMutableDictionary *) [super toJSONObject];
	[o setObject:@"optionlist" forKey:@"type"];
	
	NSMutableArray *jsonArray = [NSMutableArray new];
	[o setObject:jsonArray forKey:@"optionlist"];
	
	for(int i = 0; i < self.optionList.count; i++) {
		[jsonArray addObject:[self.optionList[i] toJSONObject]];
	}
	
	return o;
}

@end
