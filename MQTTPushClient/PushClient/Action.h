/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@interface Action : NSObject

@property(copy) NSString *name;
@property(copy) NSString *topic;
@property(copy) NSString *content;
@property BOOL retainFlag;

@end
