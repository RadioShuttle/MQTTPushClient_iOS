/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "AppDelegate.h"
#import "FIRMessaging.h"
#import "FCMData.h"
#import "Account.h"
#import "Action.h"
#import "Cmd.h"
#import "Topic.h"
#import "Action.h"
#import "Connection.h"
#import "AccountList.h"
#import "Utils.h"
#import "DashConsts.h"
#import "DashUtils.h"
#import "DashMessage.h"
#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Trace.h"
#import <stdatomic.h>

enum ConnectionState {
	StateBusy,
	StateReady
};

@interface Connection()

@property dispatch_queue_t serialQueue;
@property enum ConnectionState state;
@property atomic_int noOfActiveDashRequests;
@end

@implementation Connection

- (instancetype)init {
	self = [super init];
	if (self) {
		_serialQueue = dispatch_queue_create("connection.serial.queue", NULL);
		_state = StateReady;
	}
	return self;
}

- (void)postServerUpdateNotification {
	[self postServerUpdateNotification:nil];
}

- (void)postServerUpdateNotification:(NSDictionary *)userInfo {
	self.state = StateReady;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self userInfo:userInfo];
}

- (void)applyFcmData:(NSData *)data forAccount:(Account *)account {
	FCMData *fcmData = [[FCMData alloc] init];
	unsigned char *p = (unsigned char *)data.bytes;
	int count = (p[0] << 8) + p[1];
	fcmData.app_id = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.sender_id = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.pushserverid = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	account.pushServerID = fcmData.pushserverid;
	account.fcmSenderID = fcmData.sender_id;
	TRACE(@"*** AppID: %@, SenderID: %@", fcmData.app_id, fcmData.sender_id);
	dispatch_async(dispatch_get_main_queue(), ^{
		// pushServerID must be saved to user defaults, so that extension finds account.
		[[AccountList sharedAccountList] save];
		[[FIRMessaging messaging]
		 retrieveFCMTokenForSenderID:fcmData.sender_id
		 completion:^(NSString *FCMToken, NSError *error) {
			 if (FCMToken != nil) {
				 TRACE(@"FCM token: %@", FCMToken);
				 account.fcmToken = FCMToken;
				 Connection *connection = [[Connection alloc] init];
				 dispatch_async(connection.serialQueue, ^{
					 Cmd *command = [self login: account];
					 [self disconnect:account withCommand:command];
				 });
			 } else {
				 TRACE(@"FCM token error: %@", error);
			 }
		 }];
	});
}

- (Cmd *)login:(Account *)account withMqttPassword:(NSString *)password secureTransport:(BOOL)secureTransport {
	while (self.state == StateBusy)
		[NSThread sleepForTimeInterval:0.02f];
	int port = SERVER_DEFAULT_PORT;
	NSString *host = account.host;
	NSArray *array = [account.host componentsSeparatedByString:@":"];
	if ([array count] == 2) {
		host = array[0];
		NSString *portString = array[1];
		port = portString.intValue;
	}
	Cmd *command = [[Cmd alloc] initWithHost:host port:port];
	[command helloRequest:0 secureTransport:secureTransport];
	[command loginRequest:0 uri:account.mqttURI user:account.mqttUser password:password];
	account.error = command.rawCmd.error;
	if (!account.error) {
		NSString *iOSVersion = UIDevice.currentDevice.systemVersion;
		NSString *model = UIDevice.currentDevice.model;
		NSString *system = UIDevice.currentDevice.systemName;
		NSLocale *locale = [NSLocale currentLocale];
		NSInteger millisecondsFromGMT = 1000 * [[NSTimeZone localTimeZone] secondsFromGMT];
		[command setDeviceInfo:0 clientOS:system osver:iOSVersion device:model
					  fcmToken:account.fcmToken locale:locale
		   millisecondsFromGMT:millisecondsFromGMT extra:@""];
	} else {
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification)
							   withObject:nil waitUntilDone:YES];
	}
	return command;
}

- (void)disconnect:(Account *)account withCommand:(Cmd *)command {
	[self disconnect:account withCommand:command userInfo:nil];
}

- (void)disconnect:(Account *)account withCommand:(Cmd *)command userInfo:(NSDictionary*) userInfo {
	account.error = command.rawCmd.error;
	[command bye:0];
	[command exit];
	[self performSelectorOnMainThread:@selector(postServerUpdateNotification:) withObject:userInfo waitUntilDone:YES];
}

- (void)getFcmDataAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command fcmDataRequest:0];
	account.error = command.rawCmd.error;
	if (account.error) {
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
		return;
	}
	[self applyFcmData:command.rawCmd.data forAccount:account];
	[self disconnect:account withCommand:command];
}

- (void)removeDeviceAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command removeDeviceRequest:0];
	[self disconnect:account withCommand:command];
}

- (void)getTopicsAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command getTopicsRequest:0];
	if (!command.rawCmd.error) {
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		p += 2;
		NSMutableArray *topicList = [NSMutableArray arrayWithCapacity:numRecords];
		while (numRecords--) {
			Topic *topic = [[Topic alloc] init];
			int count = (p[0] << 8) + p[1];
			p += 2;
			topic.name = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			topic.type = *p++;
			count = (p[0] << 8) + p[1];
			p += 2;
			topic.filterScript = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			[topicList addObject:topic];
		}
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name"
															   ascending:YES
																selector:@selector(caseInsensitiveCompare:)];
		[topicList sortUsingDescriptors:@[sort]];
		account.topicList = topicList;
		dispatch_async(dispatch_get_main_queue(), ^{
			/*
			 * Save accounts so that user notification extension knows
			 * about the current topic list and can apply filter scripts.
			 */
			[[AccountList sharedAccountList] save];
		});
	}
	[self disconnect:account withCommand:command];
}

- (void)getMessagesAsync:(Account *)account syncTimestamp:(NSDate *)syncTimestamp
		   syncMessageID:(int32_t)syncMessageID {
	Cmd *command = [self login:account];
	[command getMessagesRequest:0
						   date:syncTimestamp
							 id:syncMessageID];
	if (!command.rawCmd.error) {
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		p += 2;
		NSMutableArray<Message *>*messageList = [NSMutableArray arrayWithCapacity:numRecords];
		while (numRecords--) {
			Message *message = [[Message alloc] init];
			NSTimeInterval seconds = ((uint64_t)p[0] << 56) + ((uint64_t)p[1] << 48) + ((uint64_t)p[2] << 40) + ((uint64_t)p[3] << 32) + ((uint64_t)p[4] << 24) + (p[5] << 16) + (p[6] << 8) + p[7];
			message.timestamp = [NSDate dateWithTimeIntervalSince1970:seconds];
			p += 8;
			int count = (p[0] << 8) + p[1];
			p += 2;
			message.topic = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			message.content = [NSData dataWithBytes:p length:count];
			p += count;
			int msgID = (int) (((uint64_t)p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3]); // message is uint32 but wont get as big
			message.messageID = msgID;
			p += 4;
			[messageList addObject:message];
		}
		[account addMessageList:messageList updateSyncDate:YES];
	}
	[self disconnect:account withCommand:command];
}

- (void)addTopicAsync:(Account *)account name:(NSString *)name type:(enum NotificationType)type
		 filterScript:(NSString *)filterScript {
	Cmd *command = [self login:account];
	[command addTopicRequest:0 name:name type:type filterScript:filterScript];
	[self disconnect:account withCommand:command];
}

- (void)updateTopicAsync:(Account *)account name:(NSString *)name type:(enum NotificationType)type
			filterScript:(NSString *)filterScript {
	Cmd *command = [self login:account];
	[command updateTopicRequest:0 name:name type:type filterScript:filterScript];
	[self disconnect:account withCommand:command];
}

- (void)deleteTopicAsync:(Account *)account name:(NSString *)name {
	Cmd *command = [self login:account];
	[command deleteTopicRequest:0 name:name];
	[self disconnect:account withCommand:command];
}

- (void)getActionsAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command getActionsRequest:0];
	if (!command.rawCmd.error) {
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		NSMutableArray *actionList = [NSMutableArray arrayWithCapacity:numRecords];
		p += 2;
		while (numRecords--) {
			Action *action = [[Action alloc] init];
			int count = (p[0] << 8) + p[1];
			p += 2;
			action.name = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			action.topic = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			action.content = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			action.retainFlag = p[0];
			p++;
			[actionList addObject:action];
		}
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name"
															   ascending:YES
																selector:@selector(caseInsensitiveCompare:)];
		[actionList sortUsingDescriptors:@[sort]];
		account.actionList = actionList;
	}
	[self disconnect:account withCommand:command];
}

- (void)publishMessageAsync:(Account *)account topic:(NSString *)topic payload:(NSData *)payload retain:(BOOL)retain userInfo:(NSDictionary *)userInfo {
	Cmd *command = [self login:account];
	if (!command.rawCmd.error) {
		[command mqttPublishRequest:0 topic:topic content:payload retainFlag:retain];
	}
	[self disconnect:account withCommand:command userInfo:userInfo];
}

- (void)addActionAsync:(Account *)account action:(Action *)action {
	Cmd *command = [self login:account];
	[command addActionRequest:0 action:action];
	[self disconnect:account withCommand:command];
}

- (void)updateActionAsync:(Account *)account action:(Action *)action name:(NSString *)name {
	Cmd *command = [self login:account];
	[command updateActionRequest:0 action:action name:name];
	[self disconnect:account withCommand:command];
}

- (void)deleteActionAsync:(Account *)account name:(NSString *)name {
	Cmd *command = [self login:account];
	[command deleteActionRequest:0 name:name];
	[self disconnect:account withCommand:command];
}

/* getDashboardAsync gets the latest messages (including historical data),
 the up-to-date dashboard and (sync) resources */
- (void)getDashboardAsync:(Dashboard *)dashboard localVersion:(uint64_t)localVersion timestamp:(uint64_t)timestamp messageID:(int)messageID  dashboard:(NSString *)localDashboardJS resourceDir:(NSURL *)resourceDir {
	Cmd *command = [self login:dashboard.account];

	NSMutableDictionary *resultInfo = nil;
	
	if (!command.rawCmd.error) {
		/* get lastest messages and historical data */
		[command getDashMessagesRequest:0 date:timestamp id:messageID];
		if (!command.rawCmd.error) {
			unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
			uint64_t serverVersion = [Utils charArrayToUint64:p];
			p += 8;

			int noOfMsgs = (p[0] << 8) + p[1];
			p += 2;
			
			NSMutableDictionary<NSString *, NSMutableArray<DashMessage *> *> *msgsPerTopic = [NSMutableDictionary new];
			NSMutableArray<DashMessage *> *msgs;
			while (noOfMsgs--) {
				DashMessage *message = [[DashMessage alloc] init];
				NSTimeInterval seconds = [Utils charArrayToUint64:p];
				message.timestamp = [NSDate dateWithTimeIntervalSince1970:seconds];
				p += 8;
				int count = (p[0] << 8) + p[1];
				p += 2;
				message.topic = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
				p += count;
				count = (p[0] << 8) + p[1];
				p += 2;
				message.content = [NSData dataWithBytes:p length:count];
				p += count;
				int msgID = (int) (((uint64_t) p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3]);
				message.messageID = msgID;
				p += 4;
				/* subscription status */
				message.status = (p[0] << 8) + p[1];;
				p += 2;
				
				msgs = [msgsPerTopic objectForKey:message.topic];
				if (!msgs) {
					msgs = [NSMutableArray<DashMessage *> new];
					[msgsPerTopic setObject:msgs forKey:message.topic];
				}
				[msgs addObject:message];
			}
			/* sort */
			NSEnumerator *enumerator = [msgsPerTopic keyEnumerator];
			id key;
			
			NSComparisonResult (^sortFunc)(DashMessage *, DashMessage *) = ^(DashMessage *obj1, DashMessage *obj2) {
				NSComparisonResult r = [obj1.timestamp compare:obj2.timestamp];
				if (r == NSOrderedSame) {
					if (obj1.messageID < obj2.messageID) {
						r = NSOrderedAscending;
					} else if (obj1.messageID > obj2.messageID) {
						r = NSOrderedDescending;
					}
				}
				return r;
			};
										   
			msgs = [NSMutableArray<DashMessage *> new]; // latest messages
			NSMutableDictionary<NSString *, NSArray<DashMessage *> *> *historicalData = [NSMutableDictionary new];
			while ((key = [enumerator nextObject])) {
				NSArray *vals = [msgsPerTopic objectForKey:key];
				NSArray *sortedArray = [vals sortedArrayUsingComparator:sortFunc];
				[historicalData setObject:sortedArray forKey:key];
				[msgs addObject:[sortedArray lastObject]];
			}
			NSArray<DashMessage *> *dashMessages = [msgs sortedArrayUsingComparator: sortFunc];

			NSString *dashboardJS = nil;
			BOOL invalidVersion = NO;
			
			/* get dashboard if there is a newer version on the server */
			if (serverVersion > 0 && localVersion != serverVersion) {
				invalidVersion = YES; // the local version is not up-to-date;
				[command getDashboardRequest:0];
				if (!command.rawCmd.error) {
					unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
					serverVersion = [Utils charArrayToUint64:p];
					p += 8;
					int count = (p[0] << 8) + p[1];
					p += 2;
					dashboardJS = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
					// NSLog(@"Dashboard: %@", dashboard);
				}
			}

			if (!command.rawCmd.error) {
				NSString *currentDash;
				if (![Utils isEmpty:dashboardJS]) {
					currentDash = dashboardJS;
				} else {
					currentDash = localDashboardJS;
				}
				[self syncImages:command dash:currentDash resourceDir:resourceDir];
				
				if (!command.rawCmd.error) {					
					resultInfo = [NSMutableDictionary new];
					[resultInfo setObject:@"getDashboardRequest" forKey:@"response"];
					if (dashboardJS) {
						[resultInfo setObject:dashboardJS forKey:@"dashboardJS"];
						[resultInfo setObject:[NSNumber numberWithUnsignedLongLong:serverVersion] forKey:@"serverVersion"];
					}
					[resultInfo setObject:dashMessages forKey:@"dashMessages"];
					[resultInfo setObject:historicalData forKey:@"historicalData"];
					[resultInfo setObject:[NSDate dateWithTimeIntervalSince1970:timestamp] forKey:@"msgs_since_date"];
					[resultInfo setObject:[NSNumber numberWithUnsignedLongLong:messageID] forKey:@"msgs_since_seqno"];
				}
			}
		}
		[self disconnect:dashboard.account withCommand:command userInfo:resultInfo];
	}
	atomic_fetch_sub(&_noOfActiveDashRequests, 1);
}

-(void) syncImages:(Cmd *)command dash:(NSString *)currentDash resourceDir:(NSURL *)resourceDir {
	if (![Utils isEmpty:currentDash]) {
		NSData *jsonData = [currentDash dataUsingEncoding:NSUTF8StringEncoding];
		NSError *error;
		NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		if (error) {
			NSLog(@"sync images, json parse error.");
		} else {
			NSArray *groups = [jsonDict valueForKey:@"groups"];
			NSArray *resources = [jsonDict valueForKey:@"resources"];
			
			NSMutableSet *resourceNames = [NSMutableSet new];
			NSString *uri;
			NSString *resourceName;
			NSString *internalFilename;
			NSURL *localDir = [DashUtils getUserFilesDir:resourceDir];
			NSURL *fileURL;
			
			//TODO: remove the following 2 lines after test. Otherwise all images will be reloaded from server
			// [[NSFileManager defaultManager] removeItemAtURL:localDir error:nil];
			// localDir = [DashUtils getUserFilesDir:resourceDir];

			/* check if referenced resources exists */
			for(int i = 0; i < [resources count]; i++) {
				uri = [resources objectAtIndex:i];
				if ([DashUtils isUserResource:uri]) {
					resourceName = [DashUtils getURIPath:uri];
					internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
					fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
					if (![DashUtils fileExists:fileURL]) {
						// NSLog(@"internal filename not exists: %@", internalFilename);
						[resourceNames addObject:resourceName];
					}
				}
			}
			
			NSDictionary * group;
			NSArray *items;
			NSDictionary *item;
			for(int i = 0; i < [groups count]; i++) {
				group = [groups objectAtIndex:i];
				items = [group valueForKey:@"items"];
				for(int j = 0; j < [items count]; j++) {
					item = [items objectAtIndex:j];
					NSString *uris[3] = {@"uri", @"uri_off", @"background_uri"};
					for(int z = 0; z < 3; z++) {
						uri = [item objectForKey:uris[z]];
						if (uri) {
							if ([DashUtils isUserResource:uri]) {
								resourceName = [DashUtils getURIPath:uri];
								internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
								fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
								if (![DashUtils fileExists:fileURL]) {
									[resourceNames addObject:resourceName];
								}
							}
						}
					}
					NSArray *optionList = [item objectForKey:@"optionlist"];
					if (optionList) {
						NSDictionary * optionItem;
						for(int z = 0; z < [optionList count]; z++) {
							optionItem = [optionList objectAtIndex:z];
							if (optionItem) {
								uri = [optionItem objectForKey:@"uri"];
								if ([DashUtils isUserResource:uri]) {
									resourceName = [DashUtils getURIPath:uri];
									internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
									fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
									if (![DashUtils fileExists:fileURL]) {
										[resourceNames addObject:resourceName];
									}
								}
							}
						}
					}
				}
			}
			
			/* get all missing resources */
			NSEnumerator *enumerator = [resourceNames objectEnumerator];
			NSString *resName;
			unsigned char *p;
			uint64_t mdate;
			int len;

			while ((resName = [enumerator nextObject])) {
				NSLog(@"missing resource: %@", resName);
				[command getResourceRequest:0 name:resName type:DASH512_PNG];
				if (command.rawCmd.error || command.rawCmd.rc != RC_OK) {
					break;
				}else {
					p = (unsigned char *)command.rawCmd.data.bytes;
					mdate = [Utils charArrayToUint64:p];
					p += 8;
					len = (int) (((uint64_t)p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3]);
					p += 4;
					NSData* data = [NSData dataWithBytes:p length:len];

					internalFilename = [NSString stringWithFormat:@"%@.%@", [resName enquoteHelios], DASH512_PNG];
					fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
					if (![data writeToURL:fileURL atomically:YES]) {
						NSLog(@"Resource file %@ could not be written.", resName);
					} else {
						NSDate *modDate = [NSDate dateWithTimeIntervalSince1970:mdate];
						NSString *dateString = [NSDateFormatter localizedStringFromDate:modDate
																			  dateStyle:NSDateFormatterShortStyle
																			  timeStyle:NSDateFormatterFullStyle];
						NSLog(@"File %@: modification date %@",internalFilename, dateString);
						NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys: modDate, NSFileModificationDate, NULL];
						[[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:[fileURL path] error:&error];
						if (error) {
							NSLog(@"Error: %@ %@", error, [error userInfo]); //TODO
						}
					}
				}
			}
		}
	}
}

-(void)setDashboardForAccountAsync:(Account *)account json:(NSDictionary *)jsonObj prevVersion:(uint64_t)version itemID:(uint32_t)itemID userInfo:(NSDictionary *)userInfo {

	//TODO: saving on push.radioshuttle.de is disabled until test completed. remove after test:
	if ([account.host isEqualToString:@"push.radioshuttle.de"]) {
		NSMutableDictionary *errInfo = [NSMutableDictionary new];
		[errInfo setValue:@"Saving on \"push.radioshuttle.de\" is disabled." forKey:NSLocalizedDescriptionKey];
		account.error = [NSError errorWithDomain:@"ios_development" code:400 userInfo:errInfo];
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification:) withObject:userInfo waitUntilDone:YES];
		return;
	}
	// end
	
	NSError *error;
	NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonObj options:0 error:&error];
	if (error) {
		/* unexprectd error - should not occur  */
		account.error = error;
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification:) withObject:userInfo waitUntilDone:YES];
		return;
	}
	
	NSMutableDictionary *resultInfo = userInfo ? [userInfo mutableCopy] : [NSMutableDictionary new];
	
	Cmd *command = [self login:account];
	if (!command.rawCmd.error) {
		//TODO: manage resources (update on server, download, ...)
		
		[command setDashboard:0 version:version itemID:itemID dashboard:jsonData];
		if (!command.rawCmd.error) {
			//TODO: handle MQTT error (e.g. subscribe dashboard topic error)
			if (command.rawCmd.rc == RC_OK) {
				unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
				uint64_t newVersion = [Utils charArrayToUint64:p];
				if (newVersion == 0) {
					/* version error */
					[resultInfo setObject:@(YES) forKey:@"invalidVersion"];
				} else {
					[resultInfo setObject:@(newVersion) forKey:@"serverVersion"];
					NSString* dashboardStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
					[resultInfo setObject:dashboardStr forKey:@"dashboardJS"];
				}
			} else {
				// should never occur
				NSMutableDictionary *errInfo = [NSMutableDictionary new];
				[errInfo setValue:@"Saving dashboard failed (invalid args)." forKey:NSLocalizedDescriptionKey];
				command.rawCmd.error= [NSError errorWithDomain:@"RequsetError" code:400 userInfo:errInfo];
			}
		}
	}
	[self disconnect:account withCommand:command userInfo:resultInfo];
}

#pragma mark - public methods

- (Cmd *)login:(Account *)account {
	return [self login:account withMqttPassword:account.mqttPassword secureTransport:account.secureTransportToPushServer];
}

- (void)getFcmDataForAccount:(Account *)account {
	account.error = nil;
	dispatch_async(self.serialQueue, ^{[self getFcmDataAsync:account];});
}

- (void)removeDeviceForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self removeDeviceAsync:account];});
}

- (void)getMessagesForAccount:(Account *)account {
	NSDate *syncTimestamp = account.cdaccount.syncTimestamp;
	int32_t syncMessageID = account.cdaccount.syncMessageID;
	dispatch_async(self.serialQueue, ^{
		[self getTopicsAsync:account];
		[self getMessagesAsync:account syncTimestamp:syncTimestamp syncMessageID:syncMessageID];
	});
}

- (void)publishMessageForAccount:(Account *)account action:(Action *)action {
	NSData *payload = [action.content dataUsingEncoding:NSUTF8StringEncoding];
	[self publishMessageForAccount:account topic:action.topic payload:payload retain:action.retainFlag userInfo:nil];
}

- (void)getTopicsForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getTopicsAsync:account];});
}

- (void)addTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type
			  filterScript:(NSString *)filterScript {
	dispatch_async(self.serialQueue, ^{[self addTopicAsync:account name:name type:type
											  filterScript:filterScript];});
}

- (void)updateTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type
				 filterScript:(NSString *)filterScript {
	dispatch_async(self.serialQueue, ^{[self updateTopicAsync:account name:name type:type
												 filterScript:filterScript];});
}

- (void)deleteTopicForAccount:(Account *)account name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self deleteTopicAsync:account name:name];});
}

- (void)getActionsForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getActionsAsync:account];});
}

- (void)addActionForAccount:(Account *)account action:(Action *)action {
	dispatch_async(self.serialQueue, ^{[self addActionAsync:account action:action];});
}

- (void)updateActionForAccount:(Account *)account action:(Action *)action name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self updateActionAsync:account action:action name:name];});
}

- (void)deleteActionForAccount:(Account *)account name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self deleteActionAsync:account name:name];});
}

- (void)getDashboardForAccount:(Dashboard *)dashboard {
	uint64_t vers = dashboard.localVersion;
	uint64_t ts = [dashboard.lastReceivedMsgDate timeIntervalSince1970];
	int messageID = dashboard.lastReceivedMsgSeqNo;
	NSString *db = dashboard.dashboardJS;
	NSURL *resourceDir = dashboard.account.cacheURL;
	
	atomic_fetch_add(&_noOfActiveDashRequests, 1);
	
	dispatch_async(self.serialQueue, ^{[self getDashboardAsync:dashboard localVersion:vers timestamp:ts messageID:messageID dashboard:db resourceDir:resourceDir];});
}

- (void)publishMessageForAccount:(Account *)account topic:(NSString *)topic payload:(NSData *)payload retain:(BOOL)retain userInfo:(NSDictionary *)userInfo {
	dispatch_async(self.serialQueue, ^{[self publishMessageAsync:account topic:topic payload:payload retain:retain userInfo: userInfo];});
}

-(void)saveDashboardForAccount:(Account *)account json:(NSDictionary *)jsonObj prevVersion:(uint64_t)version itemID:(uint32_t)itemID userInfo:(NSDictionary *)userInfo {
	
	dispatch_async(self.serialQueue, ^{[self setDashboardForAccountAsync:account json:(NSDictionary *)jsonObj prevVersion:version itemID:(uint32_t)itemID userInfo:(NSDictionary *)userInfo];});
}


-(int)activeDashboardRequests {
	return atomic_load(&_noOfActiveDashRequests);
}

@end
