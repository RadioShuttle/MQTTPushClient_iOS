/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "DashItem.h"
#import "DashMessage.h"
#import "Account.h"
#import "Dashboard.h"

@interface DashJavaScriptTask : NSObject

-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t)version account:(Account *)account;
-(void)execute;

@property NSDate *timestamp;
@property DashMessage *message;
@property DashItem *item;
@property uint64_t version;
@property Account *account;

@property NSMutableDictionary *data;

@end
