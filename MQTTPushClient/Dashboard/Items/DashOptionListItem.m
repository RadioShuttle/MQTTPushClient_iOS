/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "DashOptionListItem.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Utils.h"

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

-(id)copyWithZone:(NSZone *)zone {
	DashOptionListItem *clone = [[[self class] alloc] init];
	
	clone.value = self.value;
	clone.displayValue = self.displayValue;
	clone.imageURI = self.imageURI;
	
	return clone;
}

- (BOOL)isEqual:(id)object {
	BOOL eq = NO;
	if (self == object) {
		eq = YES;
	} else if ([object isKindOfClass:[DashOptionListItem class]]) {
		if (!eq) {
			DashOptionListItem *obj = (DashOptionListItem *) object;
			eq = [Utils areEqual:self.value s2:obj.value] && [Utils areEqual:self.displayValue s2:obj.displayValue] && [Utils areEqual:self.imageURI s2:obj.imageURI];
		}
	}
	return eq;
}

@end
