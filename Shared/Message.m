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

+ (NSString *)msgFromData:(NSData *)data {
	NSString *msg;
	
	// Try UTF-8 encoding:
	msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg != nil) {
		return msg;
	}
	// Try CP1252 (Windows Latin 1) encoding:
	msg = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
	if (msg != nil) {
		return msg;
	}
	// Fallback:
	return [NSString stringWithFormat:@"%*.*s",
			(int)data.length, (int)data.length, data.bytes];
}

@end
