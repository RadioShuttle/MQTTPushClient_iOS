/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "Dashboard.h"
#import "Account.h"
#import "DashUtils.h"
#import "NSString+HELUtils.h"
#import "Utils.h"

@implementation Dashboard

- (instancetype)initWithAccount:(Account *)account {
	self.account = account;
	if ((self = [super init]) != nil) {
		[self load];
	}
	return self;
}

/* load local stored dashboard */
- (void)load {

	self.dashboardJS = @"";
	self.localVersion = 0L;
	self.lastReceivedMsgDate = [NSDate dateWithTimeIntervalSince1970:0L];
	self.lastReceivedMsgSeqNo = 0;
	
	NSURL *fileURL = [DashUtils appendStringToURL:self.account.cacheURL str:@"dashboard.js"];
	NSError *error;
	NSString *db = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		NSLog(@"Error reading file: %@", error.localizedDescription);
	} else {
		NSRange r = [db rangeOfString:@"\n"];
		if (r.location != NSNotFound) {
			NSString *versionStr = [db substringToIndex:r.location];
			self.localVersion = [Utils stringToUint64:versionStr];
			self.dashboardJS = [db substringFromIndex:r.location + 1];
			NSLog(@"Local stored dashboard:\n %@", self.dashboardJS);
		}
	}
}

/* called by connection object on succesfull request */
- (void)onGetDashboardRequestFinished:(NSString *)dashboard version:(uint64_t)version receivedMsgs:(NSArray<DashMessage *> *)receivedMsgs historicalData:(NSDictionary<NSString *, NSArray<DashMessage *> *> *)historicalData lastReceivedMsgDate:(NSDate *)lastReceivedMsgDate lastReceivedMsgSeqNo:(int) lastReceivedMsgSeqNo {

	if (dashboard) {
		self.dashboardJS = dashboard;
		self.localVersion = version;

		[self saveDashboard:dashboard version:version];
	}
}

/* saves the given dashboard str (json) including dashboard version info */
- (void)saveDashboard:(NSString *)dashboard version:(uint64_t) version  {
	NSMutableString *db = [NSMutableString new];
	/* put the version info before the dashboard and separate with new line */
	[db appendString:[@(version) stringValue]];
	[db appendString:@"\n"];
	if (dashboard) {
		[db appendString:dashboard];
	}
	NSURL *fileURL = [DashUtils appendStringToURL:self.account.cacheURL str:@"dashboard.js"];
	if (![db writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
		NSLog(@"Saving dashboard failed.");
	}
}

@end

@implementation DashMessage
@end
