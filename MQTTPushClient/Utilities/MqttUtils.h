/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@interface MqttUtils : NSObject

+(void) topicValidate:(NSString *)topic wildcardAllowed:(BOOL)wildcardAllowed;
+(BOOL) topicIsMatched:(NSString *)filter topic:(NSString *)topic;

@end
