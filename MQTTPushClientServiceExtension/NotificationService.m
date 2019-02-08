/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "NotificationService.h"
#import "MessageDataHandler.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "NotificationQueue.h"

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
		Message *msg = messageList[0];
		// Single message:
		NSString *stringMessage = [Message msgFromData:msg.content];
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
