/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Account.h"

NS_ASSUME_NONNULL_BEGIN
@class DashMessage;

@interface Dashboard : NSObject

@property Account *account;

/*
 * A dashboard requires a valid account
 */
- (instancetype)initWithAccount:(Account *)account;

/*
 * Will be called after a successfull dashboard request
 *
 * dashboard - nil if the local dashboard is up to date
 * version - dashboard version no if dashboard has been updated
 * receivedMsgs - message array only containing the latest msg per topic
 * historicalData - historical data per topic
 * lastReceivedMsgDate - last received msg date
 * lastReceivedMsgSeqNo - seq no
 */
- (void)onGetDashboardRequestFinished:(NSString *)dashboard version:(uint64_t)version receivedMsgs:(NSArray<DashMessage *> *)receivedMsgs historicalData:(NSDictionary<NSString *, NSArray<DashMessage *> *> *)historicalData lastReceivedMsgDate:(NSDate *)lastReceivedMsgDate lastReceivedMsgSeqNo:(int) lastReceivedMsgSeqNo;


/* version no of local stored dashboard */
@property uint64_t localVersion;

/* last received message date and sequence no */
@property NSDate *lastReceivedMsgDate;
@property int lastReceivedMsgSeqNo;

/* current dash board in JS format*/
@property NSString *dashboardJS;

@end

@interface DashMessage : Message
@property int status;
@end


NS_ASSUME_NONNULL_END
