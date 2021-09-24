/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Account.h"
#import "DashItem.h"
#import "DashGroupItem.h"
#import "DashMessage.h"

@interface Dashboard : NSObject

@property Account *account;

/*
 * A dashboard requires a valid account
 */
- (instancetype)initWithAccount:(Account *)account;

/* returns true if the dashboard view is the preferred view mode */
+ (BOOL) showDashboard:(Account *) account;
/* set preferred view mode */
+ (void) setPreferredViewDashboard:(BOOL)pref forAccount:(Account *)account;

/* sets a new dashboard and resturns a dictionary with error info */
-(NSDictionary *)setDashboard:(NSString *)dashboard version:(uint64_t)version;
-(void)addNewMessages:(NSArray<DashMessage *> *)receivedMsgs;
/* save cached messages to have a local copy of latest messages */
-(BOOL)saveMessages;

/* last received message date and sequence no */
@property NSDate *lastReceivedMsgDate;
@property int lastReceivedMsgSeqNo;
@property NSMutableDictionary<NSString *, DashMessage *> *lastReceivedMsgs;
@property BOOL lastMsgsUnsaved;

/* current dash board in JS format*/
@property NSString *dashboardJS;
/* version no of local stored dashboard */
@property uint64_t localVersion;

/* Dashboard item data used in view controller */
@property NSArray<DashGroupItem *> *groups;
/* key is DashGroupItem.id_ */
@property NSDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems;

/* The max item id_ in groups, groupItems*/
@property int max_id;

@end
