/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface MessageDataHandler : NSObject

- (void)handleRemoteMessage:(NSDictionary *)remoteMessage forList:(NSMutableArray *)list;

@end
