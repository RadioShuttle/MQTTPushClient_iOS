/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "CDAccount+CoreDataClass.h"
#import "CDMessage+CoreDataClass.h"

static void saveRecursively(NSManagedObjectContext *context) {
	if (context.hasChanges) {
		NSError *error = nil;
		if (![context save:&error]) {
			NSLog(@"Could not save context: %@", error.localizedDescription);
		} else if (context.parentContext != nil) {
			saveRecursively(context.parentContext);
		}
	}
}

@implementation CDAccount

-(void)addMessageList:(NSArray<Message *>*)messageList updateSyncDate:(BOOL)updateSyncDate {
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
			NSLog(@"*** %d duplicate message(s)", (int)result.count);
		} else {
			CDMessage *cdmsg = [[CDMessage alloc] initWithContext:context];
			cdmsg.topic = msg.topic;
			cdmsg.content = msg.content;
			cdmsg.timestamp = msg.timestamp;
			cdmsg.messageID = msg.messageID;
			cdmsg.account = self;
		}
		if (updateSyncDate && [msg isNewerThan:latestMessage]) {
			latestMessage = msg;
		}
	}
	self.lastUpdate = [NSDate date];
	
	// Message list is from a server sync: Update syncTimestamp.
	if (updateSyncDate && latestMessage != nil) {
		self.syncTimestamp = latestMessage.timestamp;
		self.syncMessageID = latestMessage.messageID;
	}
	
	saveRecursively(context);
}

- (void)deleteMessagesBefore:(NSDate *)before {
	if (self.isDeleted || self.managedObjectContext == nil) {
		return;
	}
	NSManagedObjectContext *context = self.managedObjectContext;
	NSFetchRequest *fetchRequest = CDMessage.fetchRequest;
	if (before == nil) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@", self];
	} else {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp < %@",
								  self, before];
	}
	NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:NO];
	fetchRequest.sortDescriptors = @[sort1, sort2];

	NSArray *result = [context executeFetchRequest:fetchRequest error:NULL];

	if (result.count > 0) {
		/*
		 * Replace syncTimestamp with timestamp of newest deleted
		 * message (but only if newer than current syncTimestamp):
		 */
		CDMessage *newest = result.firstObject;
		if (newest.timestamp != nil) {
			if (self.syncTimestamp == nil
				|| [newest.timestamp compare:self.syncTimestamp] == NSOrderedDescending
				|| ([newest.timestamp compare:self.syncTimestamp] == NSOrderedSame
					&& newest.messageID > self.syncMessageID)) {
					self.syncTimestamp = newest.timestamp;
					self.syncMessageID = newest.messageID;
				}
		}
		
		for (CDMessage *msg in result) {
			[context deleteObject:msg];
		}
	}
	
	saveRecursively(context);
}

- (NSInteger)numUnreadMessages {
	NSManagedObjectContext *context = self.managedObjectContext;
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	if (self.lastRead == nil) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@", self];
	} else {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp > %@",
								  self, self.lastRead];
	}
	NSInteger cnt = [context countForFetchRequest:fetchRequest error:NULL];
	return cnt == NSNotFound ? 0 : (NSInteger)cnt;
}

- (void)markMessagesRead {
	NSManagedObjectContext *context = self.managedObjectContext;
	NSFetchRequest<CDMessage *> *fetchRequest = CDMessage.fetchRequest;
	if (self.lastRead == nil) {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@", self];
	} else {
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"account = %@ AND timestamp > %@",
								  self, self.lastRead];
	}
	fetchRequest.fetchLimit = 1;
	NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
	NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:NO];
	fetchRequest.sortDescriptors = @[sort1, sort2];
	
	NSArray *result = [context executeFetchRequest:fetchRequest error:NULL];
	if (result.count > 0) {
		CDMessage *newest = result.firstObject;
		self.lastRead = newest.timestamp;
		[context save:NULL];
	}
}

@end
