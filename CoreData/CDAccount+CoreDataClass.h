/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Message.h"

@class CDMessage;

NS_ASSUME_NONNULL_BEGIN

@interface CDAccount : NSManagedObject

- (void)addMessageList:(NSArray<Message *>*)messageList updateSyncDate:(BOOL)updateSyncDate;
- (void)deleteMessagesBefore:(nullable NSDate *)before; // Pass `nil` to delete all messages
- (NSInteger)numUnreadMessages;
- (void)markMessagesRead;

@end

NS_ASSUME_NONNULL_END

#import "CDAccount+CoreDataProperties.h"
