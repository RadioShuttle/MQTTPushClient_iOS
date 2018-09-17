/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "MessageQueuingTelemetryTransport.h"

@implementation MessageQueuingTelemetryTransport

- (instancetype)init {
	self = [super init];
	if (self) {
		_host = @"";
		_port = [NSNumber numberWithInt:MQTT_DEFAULT_PORT];
		_secureTransport = NO;
		_user = @"";
		_password = @"";
	}
	return self;
}

@end
