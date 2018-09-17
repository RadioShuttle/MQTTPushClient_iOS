/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

#define MQTT_DEFAULT_PORT 1883

@interface MessageQueuingTelemetryTransport : NSObject

@property NSString *host;
@property NSNumber *port;
@property BOOL secureTransport;
@property NSString *user;
@property NSString *password;

@end
