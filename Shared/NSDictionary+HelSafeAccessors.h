/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;

@interface NSDictionary (HelSafeAccessors)

- (NSString *)helStringForKey:(id)aKey;
- (NSNumber *)helNumberForKey:(id)aKey;
- (NSArray *)helArrayForKey:(id)aKey;
- (NSDictionary *)helDictForKey:(id)aKey;
- (NSData *)helDataForKey:(id)aKey;
- (NSDate *)helDateForKey:(id)aKey;

@end
