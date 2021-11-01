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
/* filter script init */
-(instancetype)initWithItem:(DashItem *)item message:(DashMessage *)msg version:(uint64_t)version account:(Account *)account;
/* output script init */
-(instancetype)initWithItem:(DashItem *)item publishData:(DashMessage *)publishData version:(uint64_t)version account:(Account *)account requestID:(uint32_t)requestID;

/* execute script */
-(void)execute;

@property NSDate *timestamp;
@property DashMessage *message;
@property DashItem *item;
@property uint64_t version;
@property Account *account;
@property uint32_t requestID;

@property NSMutableDictionary *data;

@end
