/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"

@interface Account()

@end

@implementation Account

- (instancetype)init {
	self = [super init];
	if (self) {
		_host = @"";
		_mqtt = [[MessageQueuingTelemetryTransport alloc] init];
		_messageList = [[NSMutableArray alloc] init];
		_topicList = [[NSMutableArray alloc] init];
	}
	return self;
}


@end
