/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDAccount+CoreDataClass.h"
#import "CDMessage+CoreDataClass.h"

@implementation CDAccount

-(void)addMessageList:(NSArray<Message *>*)messageList {
	if (messageList.count == 0) {
		return;
	}
	if (self.isDeleted || self.managedObjectContext == nil) {
		return;
	}
	NSManagedObjectContext *context = self.managedObjectContext;
	Message *latestMessage = nil;
	
	for (Message *msg in messageList) {
		
		NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp = %@ AND messageID = %d",
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
		if ([msg isNewerThan:latestMessage]) {
			latestMessage = msg;
		}
	}
	self.lastUpdate = [NSDate date];
	self.lastTimestamp = latestMessage.timestamp;
	self.lastMessageID = latestMessage.messageID;
	
	NSError *error = nil;
	if (![context save:&error]) {
		NSLog(@"Could not save background context: %@", error.localizedDescription);
	}
}

- (void)deleteMessagesBefore:(NSDate *)before {
	if (self.isDeleted || self.managedObjectContext == nil) {
		return;
	}
	NSManagedObjectContext *context = self.managedObjectContext;
	if (before == nil) {
		self.messages = nil;
	} else {
		NSFetchRequest *fetchRequest = CDMessage.fetchRequest;
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp < %@",
								  self, before];
		fetchRequest.predicate = predicate;
		NSArray *result = [context executeFetchRequest:fetchRequest error:NULL];
		if (result.count > 0) {
			for (CDMessage *msg in result) {
				[context deleteObject:msg];
			}
		}
	}
	NSError *error = nil;
	if (![context save:&error]) {
		NSLog(@"Could not save background context: %@", error.localizedDescription);
	}
}

@end
