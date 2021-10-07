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
	if ((self = [super init]) != nil) {
		self.account = account;
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
	self.lastReceivedMsgs = [NSMutableDictionary new];
	
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
			if (![self buildDashboardObjectsFromJSON:self.dashboardJS]) {
				NSLog(@"Error while building dash objects from json.");
				self.dashboardJS = @"";
				self.localVersion = 0L;
			}
		}
		
		/* load messages */
		fileURL = [DashUtils appendStringToURL:self.account.cacheURL str:@"dashboard_messages.js"];
		NSData *jsonData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
		if (error) {
			NSLog(@"Error reading file: %@", error.localizedDescription);
		} else {
			NSDictionary *msgObjJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
			if (error) {
				NSLog(@"Error while parsing messages json: %@", error);
				return;
			}
			NSArray * msgArrayJSON = msgObjJSON[@"messageArray"];
			NSMutableDictionary<NSString *, DashMessage *> *dashMessages = [NSMutableDictionary new];
			DashMessage *msg;
			for(int i = 0; i < [msgArrayJSON count]; i++) {
				msg = [[DashMessage alloc] initWithJSON:msgArrayJSON[i]];
				[dashMessages setObject:msg forKey:msg.topic];
			}
			NSTimeInterval ts = [[msgObjJSON helNumberForKey:@"timestamp"] doubleValue] ;
			self.lastReceivedMsgDate = [NSDate dateWithTimeIntervalSince1970:ts];
			self.lastReceivedMsgSeqNo = [[msgObjJSON helNumberForKey:@"lastReceivedMsgSeqNo"] intValue];
			self.lastReceivedMsgs = dashMessages;
		}
	}
}

-(NSDictionary *)setDashboard:(NSString *)dashboard version:(uint64_t)version {
	NSMutableDictionary *resultInfo = [NSMutableDictionary new];

	/* updated dashboard */
	if (dashboard) {
		BOOL versionError = self.localVersion != 0 && self.localVersion != version;
		if ([self saveDashboard:dashboard version:version]) {
			if (![self buildDashboardObjectsFromJSON:dashboard]) {
				/* this error should never occur (while development only;-)*/
				[resultInfo setObject:@"The received dashboard has an invalid format." forKey:@"dashboard_err"];
			} else {
				if (versionError) {
					[resultInfo setObject:@"Dashboard has been replaced by a newer version." forKey:@"dashboard_err"];
				}
				[resultInfo setObject:[NSNumber numberWithBool:YES] forKey:@"dashboard_new"];
				self.dashboardJS = dashboard;
				self.localVersion = version;
			}
		} else {
			[resultInfo setObject:@"Error while saving dashboard." forKey:@"dashboard_err"];
		}
	}
	return resultInfo;
}

-(void)addNewMessages:(NSArray<DashMessage *> *)receivedMsgs {
	
	/* new messages */
	if ([receivedMsgs count] > 0) {
		/* saving messages is handled by view controller to prevent frequent saves */
		self.lastMsgsUnsaved = YES;
		DashMessage *newestMsg = nil, *msg;
		for(int i = 0; i < [receivedMsgs count]; i++) {
			msg = receivedMsgs[i];
			if (!newestMsg || [msg isNewerThan:newestMsg]) {
				newestMsg = msg;
			}
			[self.lastReceivedMsgs setObject:msg forKey:msg.topic];
		}
		self.lastReceivedMsgDate = newestMsg.timestamp;
		self.lastReceivedMsgSeqNo = newestMsg.messageID;
	}
}

-(BOOL)saveMessages {
	BOOL ok = YES;
	
	if (self.lastMsgsUnsaved) {
		NSMutableDictionary *jsonObj = [NSMutableDictionary new];
		NSMutableArray *jsonMsgs = [NSMutableArray new];
		
		NSEnumerator *enumerator = [self.lastReceivedMsgs objectEnumerator];
		id value;
		
		while ((value = [enumerator nextObject])) {
			[jsonMsgs addObject:[(DashMessage *) value toJSON]];
		}
		
		[jsonObj setObject:[NSNumber numberWithDouble:[self.lastReceivedMsgDate timeIntervalSince1970]] forKey:@"timestamp"];

		[jsonObj setObject:[NSNumber numberWithInteger:self.lastReceivedMsgSeqNo] forKey:@"lastReceivedMsgSeqNo"];
		[jsonObj setObject:jsonMsgs forKey:@"messageArray"];
		
		NSData *data =[NSJSONSerialization dataWithJSONObject:jsonObj options:0 error:nil];
		
		NSURL *fileURL = [DashUtils appendStringToURL:self.account.cacheURL str:@"dashboard_messages.js"];
		ok = [data writeToURL:fileURL atomically:YES];
		
		/*
		NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"%@", strData);
		*/
		
	}
	self.lastMsgsUnsaved = NO;
	
	return ok;
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

- (BOOL) buildDashboardObjectsFromJSON:(NSString *)dashboardJS {
	if (dashboardJS) {
		NSData *jsonData = [dashboardJS dataUsingEncoding:NSUTF8StringEncoding];
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

-(DashItem *)getItemForID:(uint32_t) itemID indexPathArr:(NSMutableArray *)indexPathArr {
	DashItem *foundItem = nil;
	DashGroupItem *groupItem;
	DashItem *item;

	/* find dash object */
	for(int i = 0; i < self.groups.count; i++) {
		groupItem = self.groups[i];
		NSArray<DashItem *> *items = self.groupItems[@(groupItem.id_)];
		for(int j = 0; j < items.count; j++) {
			item = items[j];
			if (item.id_ == itemID) {
				if (indexPathArr) {
					NSIndexPath *loc = [NSIndexPath indexPathForRow:j inSection:i];
					[indexPathArr addObject:loc];
				}
				foundItem = item;
				break;
			}
		}
	}
	return foundItem;
}

#pragma mark - Dashboard view preferrences

+ (NSDictionary *) setPreferredViewDashboard:(BOOL)prefer forAccount:(Account *)account {
	NSDictionary *dict = [Dashboard loadDashboardSettings:account];
	NSMutableDictionary *settings;
	if (dict) {
		settings = [dict mutableCopy];
	} else {
		settings = [NSMutableDictionary new];
	}
	[settings setObject:[NSNumber numberWithBool:prefer] forKey:@"showDashboard"];
	[Dashboard saveDashboardSettings:account settings:settings];
	return settings;
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
