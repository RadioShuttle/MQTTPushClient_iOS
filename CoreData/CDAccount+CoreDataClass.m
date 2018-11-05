/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDAccount+CoreDataClass.h"
#import "CDMessage+CoreDataClass.h"

@implementation CDAccount

-(void)addMessageList:(NSArray<Message *>*)messageList {
	NSManagedObjectContext *context = self.managedObjectContext;
	if (context == nil) {
		return;
	}
	for (Message *msg in messageList) {
		
		NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp = %@ AND messageID = %@",
								  self, msg.timestamp, msg.messageID];
		fetchRequest.predicate = predicate;
		NSArray *result = [context executeFetchRequest:fetchRequest error:NULL];
		if (result.count > 0) {
			for (CDMessage *msg in result) {
				[context deleteObject:msg];
			}
		}
		
		CDMessage *cdmsg = [[CDMessage alloc] initWithContext:context];
		cdmsg.topic = msg.topic;
		cdmsg.content = msg.content;
		cdmsg.timestamp = msg.timestamp;
		cdmsg.messageID = msg.messageID;
		cdmsg.account = self;
	}
	self.last_update = [NSDate date];
	NSError *error = nil;
	if (![context save:&error]) {
		NSLog(@"Could not save background context: %@", error.localizedDescription);
	}
}

@end
