/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "MessageQueuingTelemetryTransport.h"
#import <Foundation/Foundation.h>

#define SERVER_DEFAULT_PORT 2033

@interface Account : NSObject

@property NSString *host;
@property MessageQueuingTelemetryTransport *mqtt;
@property NSString *pushServerID;
@property NSMutableArray *messageList;
@property NSError *error;

@end
