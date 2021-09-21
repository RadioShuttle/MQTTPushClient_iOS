/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"

#import "Account.h"
#import "Dashboard.h"
#import "DashUtils.h"
#import "DashItem.h"
#import "DashGroupItem.h"
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
			// NSLog(@"Local stored dashboard:\n %@", self.dashboardJS);
			if (![self buildDashboardObjectsFromJSON]) {
				NSLog(@"Error while building dash objects from json.");
			}
		}
	}
}

/* called by connection object on succesfull request */
- (void)onGetDashboardRequestFinished:(NSString *)dashboard version:(uint64_t)version receivedMsgs:(NSArray<DashMessage *> *)receivedMsgs historicalData:(NSDictionary<NSString *, NSArray<DashMessage *> *> *)historicalData lastReceivedMsgDate:(NSDate *)lastReceivedMsgDate lastReceivedMsgSeqNo:(int) lastReceivedMsgSeqNo {

	NSMutableDictionary *resultInfo = [NSMutableDictionary new];
	
	/* updated dashboard */
	if (dashboard) {
		self.dashboardJS = dashboard;
		self.localVersion = version;
		if ([self saveDashboard:dashboard version:version]) {
			if (![self buildDashboardObjectsFromJSON]) {
				/* this error should never occur (while development only;-)*/
				[resultInfo setObject:@"The received dashboard has an invalid format." forKey:@"dashboard_err"];
			} else {
				[resultInfo setObject:[NSNumber numberWithBool:YES] forKey:@"dashboard_new"];
			}
		} else {
			[resultInfo setObject:@"Error while saving dashboard." forKey:@"dashboard_err"];
		}
	}
	/* new messages */
	//TODO: new messages
	
	
	//TODO: historical data
	
	if ([resultInfo count] > 0) { // anything new?
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DashboardDataUpdateNotification" object:self userInfo:resultInfo];
	}

}

/* saves the given dashboard str (json) including dashboard version info */
- (BOOL)saveDashboard:(NSString *)dashboard version:(uint64_t) version  {
	NSMutableString *db = [NSMutableString new];
	/* put the version info before the dashboard and separate with new line */
	[db appendString:[@(version) stringValue]];
	[db appendString:@"\n"];
	if (dashboard) {
		[db appendString:dashboard];
	}
	NSURL *fileURL = [DashUtils appendStringToURL:self.account.cacheURL str:@"dashboard.js"];
	BOOL ok = [db writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
	if (!ok) {
		NSLog(@"Saving dashboard failed.");
	}
	return ok;
}

#pragma mark - dashboard creation and modification

- (BOOL) buildDashboardObjectsFromJSON {
	if (self.dashboardJS) {
		NSData *jsonData = [self.dashboardJS dataUsingEncoding:NSUTF8StringEncoding];
		NSError *error;
		NSDictionary *dashboardObjJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		if (error) {
			NSLog(@"Error while parsing dashboard json: %@", error);
			return NO;
		}
		/* dashboard (protocol) version */
		// long p_version = [[dashboardObjJSON helNumberForKey:@"version"] longValue];
		/* max id_ of all read items */
		int max_id = 0;
		
		NSMutableArray<NSString *> *lockedResources = [NSMutableArray new];
		NSArray *resourcesArrayJSON = [dashboardObjJSON helArrayForKey:@"resources"];
		for(int i = 0; i < [resourcesArrayJSON count]; i++) {
			[lockedResources addObject:resourcesArrayJSON[i]];
		}

		NSMutableArray<DashGroupItem *> *groups = [NSMutableArray new];
		NSMutableDictionary<NSNumber *, NSArray<DashItem *> *> *groupItems = [NSMutableDictionary new];

		NSArray *groupArrayJSON = [dashboardObjJSON helArrayForKey:@"groups"];
		NSDictionary *groupJSON, *itemJSON;
		DashItem *item;
		for(int i = 0; i < [groupArrayJSON count]; i++) {
			groupJSON = groupArrayJSON[i];
			item = [DashItem createObjectFromJSON:groupJSON];
			if(![item isKindOfClass:[DashGroupItem class]]) { //should always be the case
				return NO;
			}
			if (item.id_ > max_id) {
				max_id = item.id_;
			}
			[groups addObject:(DashGroupItem *)item];
			NSMutableArray<DashItem *> *itemArray = [NSMutableArray new];
			[groupItems setObject:itemArray forKey:[NSNumber numberWithInt:item.id_]];
			NSArray *itemArrayJSON = [groupJSON helArrayForKey:@"items"];
			for(int j = 0; j < [itemArrayJSON count]; j++) {
				itemJSON = itemArrayJSON[j];
				item = [DashItem createObjectFromJSON:itemJSON];
				if (!item) {
					return NO;
				}
				if (item.id_ > max_id) {
					max_id = item.id_;
				}
				[itemArray addObject:item];
			}
		}
		self.max_id = max_id;
		self.groups = groups;
		self.groupItems = groupItems;
	}
	return YES;
}


#pragma mark - Dashboard view preferrences

+ (void) setPreferredViewDashboard:(BOOL)prefer forAccount:(Account *)account {
	NSDictionary *dict = [Dashboard loadDashboardSettings:account];
	NSMutableDictionary *settings;
	if (dict) {
		settings = [dict mutableCopy];
	} else {
		settings = [NSMutableDictionary new];
	}
	[settings setObject:[NSNumber numberWithBool:prefer] forKey:@"showDashboard"];
	[Dashboard saveDashboardSettings:account settings:settings];
}

+ (BOOL)showDashboard:(Account *)account {
	NSDictionary * settings = [Dashboard loadDashboardSettings:account];
	return [[settings objectForKey:@"showDashboard"] boolValue];
}

+(NSDictionary *) loadDashboardSettings:(Account *) account {
	NSURL *fileURL = [DashUtils appendStringToURL:account.cacheURL str:@"dashboard_settings.plist"];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfURL:fileURL];
	return settings;
}

+(BOOL) saveDashboardSettings:(Account *) account settings:(NSDictionary *) settings {
	NSURL *fileURL = [DashUtils appendStringToURL:account.cacheURL str:@"dashboard_settings.plist"];
	return [settings writeToURL:fileURL atomically:YES];
}

@end

@implementation DashMessage
@end
