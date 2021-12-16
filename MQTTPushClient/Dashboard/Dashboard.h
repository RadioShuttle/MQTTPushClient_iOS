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
+ (NSDictionary *) setPreferredViewDashboard:(BOOL)pref forAccount:(Account *)account;

/* load/save preferences (zoom_level, ...) */
+(NSDictionary *) loadDashboardSettings:(Account *) account;
+(BOOL) saveDashboardSettings:(Account *) account settings:(NSDictionary *) settings;

/* sets a new dashboard and resturns a dictionary with error info */
-(NSDictionary *)setDashboard:(NSString *)dashboard version:(uint64_t)version;
-(void)addNewMessages:(NSArray<DashMessage *> *)receivedMsgs;
-(void)addHistoricalData:(NSDictionary<NSString *, NSArray<DashMessage *> *> *)historicalData;
/* save cached messages to have a local copy of latest messages */
-(BOOL)saveMessages;

/* returns dashitem for the given item id and returns item position in indexPathArr  */
-(DashItem *)getItemForID:(uint32_t) itemID indexPathArr:(NSMutableArray *)indexPathArr;

/* returns an unmodified item clone for the given id , e.g. for editing */
-(DashItem *)getUnmodifiedItemForID:(uint32_t) itemID;


/* last received message date and sequence no */
@property NSDate *lastReceivedMsgDate;
@property int lastReceivedMsgSeqNo;
@property NSMutableDictionary<NSString *, DashMessage *> *lastReceivedMsgs;
@property NSMutableDictionary<NSString *, NSMutableArray<DashMessage *> *> *historicalData;
@property BOOL lastMsgsUnsaved;

/* current dash board in JS format*/
@property NSString *dashboardJS;
/* version no of local stored dashboard */
@property uint64_t localVersion;

/* Dashboard item data used in view controller */
@property NSArray<DashGroupItem *> *groups;
/* key is DashGroupItem.id_ */
@property NSDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems;
/* all items (including groups) unmodified. */
@property NSDictionary<NSNumber *, DashItem *> *unmodifiedItems;
@property NSArray<NSString *> *resources;

/* cached webviews */
@property NSMutableDictionary *cachedCustomViews;
@property uint64_t cachedCustomViewsVersion;

/* The max item id_ in groups, groupItems*/
@property int max_id;

@end
