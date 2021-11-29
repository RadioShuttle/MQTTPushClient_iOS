/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "Utils.h"
#import "Trace.h"

@implementation Utils


+ (NSString *)deviceId {
	static NSString *_theDeviceID;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUUID *identifier = [[UIDevice currentDevice] identifierForVendor];
		while (identifier == nil) {
			// Can happen after the device has been restarted but before the user has unlocked the device.
			[NSThread sleepForTimeInterval:1.0];
			identifier = [[UIDevice currentDevice] identifierForVendor];
		};
		_theDeviceID = identifier.UUIDString;
		TRACE(@"deviceId = %@", _theDeviceID);
	});
	return _theDeviceID;
}

+ (uint64_t)charArrayToUint64:(unsigned char *)p {
	return ((uint64_t)p[0] << 56) + ((uint64_t)p[1] << 48) + ((uint64_t)p[2] << 40) + ((uint64_t)p[3] << 32) + (p[4] << 24) + (p[5] << 16) + (p[6] << 8) + p[7];
}

+(BOOL) isEmpty:(NSString *)str {
	return [[str stringByTrimmingCharactersInSet:
			 [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0;
}

+ (uint64_t)stringToUint64:(NSString *)str {
	NSScanner *scanner = [NSScanner scannerWithString:str];
	unsigned long long convertedValue = 0;
	[scanner scanUnsignedLongLong:&convertedValue];
	return convertedValue;
}

+(BOOL) areEqual:(NSString *)s1 s2:(NSString *)s2 {
	return [(s1 ? s1 : @"") isEqualToString:(s2 ? s2 : @"")];
}
@end
