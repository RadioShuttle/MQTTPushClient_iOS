/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import UserNotifications;
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
			return; // Account does not exit anymore.
		}
		
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
					NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					if (content == nil) {
						NSLog(@"Unexpected JSON data (invalid Base64 text)");
						continue;
					}
					NSNumber *messageID = array[2];
					if (![messageID isKindOfClass:[NSNumber class]]) {
						NSLog(@"Unexpected JSON data (invalid sequence number)");
						continue;
					}
					
					NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp = %@ AND messageID = %@",
											  cdaccount, date, messageID];
					fetchRequest.predicate = predicate;
					NSArray *result = [bgContext executeFetchRequest:fetchRequest error:NULL];
					if (result.count > 0) {
						for (CDMessage *msg in result) {
							[bgContext deleteObject:msg];
						}
					}
					
					CDMessage *msg = [[CDMessage alloc] initWithContext:bgContext];
					msg.topic = topic;
					msg.content = content;
					msg.timestamp = date;
					msg.messageID = messageID;
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
