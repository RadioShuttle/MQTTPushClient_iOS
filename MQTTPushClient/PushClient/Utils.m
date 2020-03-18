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



@end
