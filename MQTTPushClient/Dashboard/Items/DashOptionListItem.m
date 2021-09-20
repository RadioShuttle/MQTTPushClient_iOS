/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionListItem.h"
#import "NSDictionary+HelSafeAccessors.h"

@implementation DashOptionListItem

- (instancetype)init
{
	return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(NSDictionary *) dictObj {
	self = [super init];

	self.value = [dictObj helStringForKey:@"value"];
	self.displayValue = [dictObj helStringForKey:@"displayvalue"];
	self.imageURI = [dictObj helStringForKey:@"uri"];

	return self;
}

@end
