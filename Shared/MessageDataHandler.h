/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
#import "Account.h"

@interface MessageDataHandler : NSObject

+ (NSArray<Message *>*)messageListFromRemoteMessage:(NSDictionary *)remoteMessage forAccount:(Account *)account;
@end
