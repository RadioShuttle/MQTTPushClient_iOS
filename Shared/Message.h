/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Message : NSObject

@property NSDate *timestamp;
@property int32_t messageID;
@property(copy) NSString *topic;
@property(copy) NSData *content;
@property int priority;

- (BOOL)isNewerThan:(nullable Message *)other;

+ (NSString *)msgFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
