/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import UserNotifications;
#import "Message.h"
#import "MessageDataHandler.h"

@implementation MessageDataHandler

- (void)handleRemoteMessage:(NSDictionary *)remoteMessage forList:(NSMutableArray *)list {
	NSData *json = [remoteMessage[@"messages"] dataUsingEncoding:NSUTF8StringEncoding];
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
				// Sort according to `date`, newest entry first:
				[list sortUsingComparator:^NSComparisonResult(Message *message1, Message *message2) {
					return [message2.date compare:message1.date];
				}];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageNotification" object:message];
			}
		}];
	}
}


@end
