/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
#import "Message.h"

@interface MessageDataHandler : NSObject

+ (NSArray<Message *>*)messageListFromRemoteMessage:(NSDictionary *)remoteMessage
											maxPrioPtr:(NSInteger *)maxPrioPtr ;
@end
