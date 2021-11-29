/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (NSString *)deviceId;
+ (uint64_t)charArrayToUint64:(unsigned char *)p;
+ (uint64_t)stringToUint64:(NSString *)str;

+(BOOL) isEmpty:(NSString *)str;
/* tests if s1 is equal to s2 where nil and @"" are treated as equal */
+(BOOL) areEqual:(NSString *)s1 s2:(NSString *)s2;

@end

NS_ASSUME_NONNULL_END
