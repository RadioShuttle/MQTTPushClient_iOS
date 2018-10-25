/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import UserNotifications;
#import "Message.h"
#import "MessageDataHandler.h"
#import "CDMessage+CoreDataClass.h"

@implementation MessageDataHandler

+ (void)handleRemoteMessage:(NSDictionary *)remoteMessage forAccount:(Account *)account {
	NSData *json = [remoteMessage[@"messages"] dataUsingEncoding:NSUTF8StringEncoding];
	NSArray *messages = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
	if (![messages isKindOfClass:[NSArray class]]) {
		NSLog(@"Unexpected JSON data (array expected)");
		return;
	}
	
	NSManagedObjectContext *bgContext = account.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[account.backgroundContext
											 existingObjectWithID:account.cdaccount.objectID
											 error:NULL];
		if (cdaccount == nil) {
			return;
		}
		for (NSDictionary *dictionary in messages) {
			if (![dictionary isKindOfClass:[NSDictionary class]]) {
				NSLog(@"Unexpected JSON data (dictionary expected)");
				continue;
			}
			[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *topic, NSDictionary *value, BOOL * _Nonnull stop) {
				if (![topic isKindOfClass:[NSString class]]) {
					NSLog(@"Unexpected JSON data (string topic expected)");
					return;
				}
				if (![value isKindOfClass:[NSDictionary class]]) {
					NSLog(@"Unexpected JSON data (dictionary value expected)");
					return;
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
					NSData *data = [[NSData alloc] initWithBase64EncodedString:array[1] options:0];
					if (data == nil) {
						NSLog(@"Unexpected JSON data (invalid Base64 data)");
						continue;
					}
					NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					if (text == nil) {
						NSLog(@"Unexpected JSON data (invalid Base64 text)");
						continue;
					}
					NSNumber *seqno = array[2];
					if (![seqno isKindOfClass:[NSNumber class]]) {
						NSLog(@"Unexpected JSON data (invalid sequence number)");
						continue;
					}
					NSLog(@"Insert message: %@(%@), %@, %@", date, seqno, topic, text);

					CDMessage *msg = [[CDMessage alloc] initWithContext:bgContext];
					msg.topic = topic;
					msg.text = text;
					msg.timestamp = date;
					msg.seqno = seqno;
					msg.account = cdaccount;
				}
			}];
		}
		cdaccount.last_update = [NSDate date];
		NSError *error = nil;
		if (![bgContext save:&error]) {
			NSLog(@"Could not save background context: %@", error.localizedDescription);
		}
	}];
}

@end
