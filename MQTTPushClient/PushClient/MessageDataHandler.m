/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Firebase;
@import UserNotifications;
#import "Message.h"
#import "MessageDataHandler.h"

@implementation MessageDataHandler

- (void)handleRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage forList:(NSMutableArray *)list {
	NSData *json = [remoteMessage.appData[@"messages"] dataUsingEncoding:NSUTF8StringEncoding];
	NSArray *messages = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
	for (NSDictionary *dictionary in messages) {
		[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *topic, NSDictionary *value, BOOL * _Nonnull stop) {
			NSArray *mdata = value[@"mdata"];
			for (NSArray *array in mdata) {
				NSInteger timeStamp = [array[0] integerValue];
				NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
				NSData *data = [[NSData alloc] initWithBase64EncodedString:array[1] options:0];
				NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				NSLog(@"%@, %@, %@", date, topic, text);
				Message *message = [[Message alloc] init];
				message.date = date;
				message.topic = topic;
				message.text = text;
				[list insertObject:message atIndex:0];
				[list sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					Message *message1 = obj1;
					Message *message2 = obj2;
					NSTimeInterval interval = [message1.date timeIntervalSinceDate:message2.date];
					if (interval < 0)
						return NSOrderedDescending;
					else if (interval > 0)
						return NSOrderedAscending;
					else
						return NSOrderedSame;
				}];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageNotification" object:message];
			}
		}];
	}
}


@end
