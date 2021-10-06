/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "DashItem.h"
#import "DashMessage.h"

@interface DashJavaScriptTask : NSObject

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t) dashVersion;
-(void)execute;

@property NSDate *timestamp;

@property NSMutableDictionary *data;

@end
