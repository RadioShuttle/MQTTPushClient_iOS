/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
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
