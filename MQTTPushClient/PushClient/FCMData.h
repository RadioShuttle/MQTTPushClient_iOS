/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>

@interface FCMData : NSObject

@property(copy) NSString *app_id;
@property(copy) NSString *sender_id;
@property(copy) NSString *pushserverid;

@end
