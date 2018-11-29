/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Message.h"

@implementation Message

-(BOOL) isNewerThan:(Message *)other {
	if (other == nil || other.timestamp == nil) {
		return YES;
	}
	switch ([self.timestamp compare:other.timestamp]) {
		case NSOrderedAscending:
			return NO;
		case NSOrderedSame:
			return self.messageID > other.messageID;
		case NSOrderedDescending:
			return YES;
	}
}

@end
