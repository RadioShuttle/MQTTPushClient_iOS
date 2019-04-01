/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "MessageDataHandler.h"
#import "Message.h"

@implementation MessageDataHandler

+ (NSArray<Message *>*)messageListFromRemoteMessage:(NSDictionary *)remoteMessage
											maxPrioPtr:(NSInteger *)maxPrioPtr {
	if (maxPrioPtr) {
		*maxPrioPtr = 0;
	}
	
	NSData *json = [remoteMessage[@"messages"] dataUsingEncoding:NSUTF8StringEncoding];
	NSArray *messages = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
	if (![messages isKindOfClass:[NSArray class]]) {
		NSLog(@"Unexpected JSON data (array expected)");
		return @[];
	}
	NSMutableArray<Message *>*messageList = [NSMutableArray arrayWithCapacity:messages.count];
	for (NSDictionary *dictionary in messages) {
		if (![dictionary isKindOfClass:[NSDictionary class]]) {
			NSLog(@"Unexpected JSON data (dictionary expected)");
			continue;
		}
		[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *topic, NSDictionary *value, BOOL *stop) {
			if (![topic isKindOfClass:[NSString class]]) {
				NSLog(@"Unexpected JSON data (string topic expected)");
				return;
			}
			if (![value isKindOfClass:[NSDictionary class]]) {
				NSLog(@"Unexpected JSON data (dictionary value expected)");
				return;
			}
			NSNumber *prio = value[@"prio"];
			if (![prio isKindOfClass:[NSNumber class]]) {
				prio = nil;
			}
			NSArray *mdata = value[@"mdata"];
			if (![mdata isKindOfClass:[NSArray class]]) {
				NSLog(@"Unexpected JSON data (array mdata expected)");
				return;
			}
			for (NSArray *array in mdata) {
				if (![array isKindOfClass:[NSArray class]] || array.count < 3) {
					NSLog(@"Unexpected JSON data (array[3] mdata expected)");
					continue;
				}
				NSInteger timeStamp = [array[0] integerValue];
				if (timeStamp <= 0) {
					NSLog(@"Unexpected JSON data (invalid timestamp)");
					continue;
				}
				NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
				NSData *content = [[NSData alloc] initWithBase64EncodedString:array[1] options:0];
				if (content == nil) {
					NSLog(@"Unexpected JSON data (invalid Base64 data)");
					continue;
				}
				NSNumber *messageID = array[2];
				if (![messageID isKindOfClass:[NSNumber class]]) {
					NSLog(@"Unexpected JSON data (invalid sequence number)");
					continue;
				}
				
				Message *msg = [[Message alloc] init];
				msg.timestamp = date;
				msg.messageID = messageID.intValue;
				msg.topic = topic;
				msg.content = content;
				msg.priority = prio.intValue;
				[messageList addObject:msg];
				
				if (maxPrioPtr && msg.priority > *maxPrioPtr) {
					*maxPrioPtr = msg.priority;
				}
			};
		}];
	}
	return messageList;
}

@end
