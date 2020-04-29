/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "NotificationService.h"
#import "MessageDataHandler.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "NotificationQueue.h"
#import "AccountList.h"
#import "Topic.h"
#import "JavaScriptFilter.h"

@interface NotificationService ()
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
	UNMutableNotificationContent *newContent = [request.content mutableCopy];
	
	NSDictionary *userInfo = request.content.userInfo;
	[[NotificationQueue new] addNotification:userInfo];
	
	NSInteger maxPrio = 0;
	NSArray<Message *>*messageList = [MessageDataHandler messageListFromRemoteMessage:userInfo
									  maxPrioPtr:&maxPrio];
	
	// Set badge count if there is at least one alarm message:
	newContent.badge = maxPrio >= 2 ? @(1) : nil;
	
	if (messageList.count == 0) {
		// No message:
		newContent.body = @"";
	} else if (messageList.count == 1) {
		NSString *pushServerID = userInfo[@"pushserverid"];
		NSString *accountID = userInfo[@"account"];

		Message *msg = messageList[0];
		// Single message:
		NSString *stringMessage = nil;
		Account *account = [AccountList loadAccount:pushServerID accountID:accountID];
		if (account != nil) {
			Topic *topic = [account topicWithName:msg.topic];
			if (topic != nil && topic.filterScript.length > 0) {
				JavaScriptFilter *filter = [[JavaScriptFilter alloc] initWithScript:topic.filterScript];
				NSObject *raw = [filter arrayBufferFromData:msg.content];
				NSDictionary *arg1 = @{@"raw":raw, @"text":msg, @"topic":topic.name,
									   @"receivedDate":msg.timestamp};
				NSDictionary *arg2 = @{@"user":account.mqttUser, @"mqttServer":account.mqttHost,
									   @"pushServer":account.host};
				NSError *error = nil;
				NSString *filtered = [filter filterMsg:arg1 acc:arg2
										  viewParameter:nil
												 error:&error];
				if (filtered) {
					stringMessage = filtered;
				} else {
					// XXX TODO: Handle error or timeout.
				}
			}
		}
		
		if (stringMessage == nil) {
			stringMessage = [Message msgFromData:msg.content];
		}
		newContent.body = [NSString stringWithFormat:@"%@: %@", msg.topic, stringMessage];
	} else {
		Message *msg = messageList[0];
		BOOL sameTopics = YES;
		for (NSInteger i = 1; i < messageList.count ; i++) {
			if (![messageList[i].topic isEqualToString:msg.topic]) {
				sameTopics = NO;
				break;
			}
		}
		if (sameTopics) {
			// Multiple messages with same topic:
			newContent.body = [NSString stringWithFormat:@"%@: %d new messages", msg.topic, (int)messageList.count];
		} else {
			// Multiple messages with different topics:
			newContent.body = [NSString stringWithFormat:@"%d new messages", (int)messageList.count];
		}
	}
	
	contentHandler(newContent);
}

- (void)serviceExtensionTimeWillExpire {
	// Called just before the extension will be terminated by the system.
	// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
}

@end
