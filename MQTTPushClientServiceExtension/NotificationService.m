/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "NotificationService.h"
#import "AccountList.h"
#import "MessageDataHandler.h"
#import "NSDictionary+HelSafeAccessors.h"

@interface NotificationService ()
@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    UNMutableNotificationContent *newContent = [request.content mutableCopy];
	
	NSDictionary *userInfo = request.content.userInfo;
	NSString *pushServerID = [userInfo helStringForKey:@"pushserverid"];
	
	Account *account = [AccountList loadAccount:pushServerID];
	if (account != nil) {
		NSArray<Message *>*messageList = [MessageDataHandler
										  messageListFromRemoteMessage:userInfo
										  forAccount:account];
		
		[account addMessageList:messageList];
		newContent.badge = @(messageList.count);
		if (messageList.count == 0) {
			newContent.body = @"";
		} else if (messageList.count == 1) {
			Message *msg = messageList[0];
			newContent.body = [NSString stringWithFormat:@"%@: %@", msg.topic, msg.content];
		} else {
			// Do all messages have the same topic?
			Message *msg = messageList[0];
			BOOL sameTopics = YES;
			for (NSInteger i = 1; i < messageList.count ; i++) {
				if (![messageList[i].topic isEqualToString:msg.topic]) {
					sameTopics = NO;
					break;
				}
			}
			if (sameTopics) {
				newContent.body = [NSString stringWithFormat:@"%@: %d new messages", msg.topic, (int)messageList.count];
			} else {
				newContent.body = [NSString stringWithFormat:@"%d new messages", (int)messageList.count];
			}
		}
	}

    contentHandler(newContent);
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
}

@end
