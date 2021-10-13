/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "NSDictionary+HelSafeAccessors.h"

@implementation NSDictionary (HelSafeAccessors)

- (NSString *)helStringForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSString class]] ? value : nil;
}

- (NSNumber *)helNumberForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSNumber class]] ? value : nil;
}

- (NSArray *)helArrayForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSArray class]] ? value : nil;
}

- (NSDictionary *)helDictForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

- (NSData *)helDataForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSData class]] ? value : nil;
}

- (NSDate *)helDateForKey:(id)aKey {
	id value = self[aKey];
	return [value isKindOfClass:[NSDate class]] ? value : nil;
}

@end
