/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "AppDelegate.h"
#import "FIRApp.h"
#import "FIROptions.h"
#import "FCMData.h"
#import "Account.h"
#import "Cmd.h"
#import "Connection.h"

@interface Connection()

@property dispatch_queue_t serialQueue;
@property NSString *fcmToken;

@end

@implementation Connection

- (instancetype)init {
	self = [super init];
	if (self) {
		_serialQueue = dispatch_queue_create("connection.serial.queue", NULL);
		_fcmToken = nil;
	}
	return self;
}

- (void)postServerUpdateNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self];
}

- (void)getFcmToken {
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	self.fcmToken = appDelegate.fcmToken;
}

- (void)applyFcmData:(NSData *)data forAccount:(Account *)account {
	FCMData *fcmData = [[FCMData alloc] init];
	unsigned char *p = (unsigned char *)data.bytes;
	int count = (p[0] << 8) + p[1];
	fcmData.app_id = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.sender_id = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.pushserverid = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	account.pushServerID = fcmData.pushserverid;
	FIROptions *firOptions = [[FIROptions alloc] initWithGoogleAppID:fcmData.app_id GCMSenderID:fcmData.sender_id];
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	if (![FIRApp appNamed:appName])
		[FIRApp configureWithName:appName options:firOptions];
}

- (Cmd *)login:(Account *)account {
	int port = SERVER_DEFAULT_PORT;
	NSString *host = account.host;
	NSArray *array = [account.host componentsSeparatedByString:@":"];
	if ([array count] == 2) {
		host = array[0];
		NSString *portString = array[1];
		port = portString.intValue;
	}
	Cmd *command = [[Cmd alloc] initWithHost:host port:port];
	NSString *string;
	if ([command helloRequest:0 secureTransport:account.mqtt.secureTransport] == nil) {
		int major = command.protocolMajor;
		int minor = command.protocolMinor;
		command = [[Cmd alloc] initWithHost:host port:port];
		command.protocolMajor = major;
		command.protocolMinor = minor;
		[command helloRequest:0 secureTransport:account.mqtt.secureTransport];
	}
	if (account.mqtt.secureTransport)
		string = [NSString stringWithFormat:@"ssl://%@:%@", account.mqtt.host, account.mqtt.port];
	else
		string = [NSString stringWithFormat:@"tcp://%@:%@", account.mqtt.host, account.mqtt.port];
	[command loginRequest:0 uri:string user:account.mqtt.user password:account.mqtt.password];
	return command;
}

- (void)disconnect:(Account *)account withCommand:(Cmd *)command {
	account.error = command.rawCmd.error;
	[command bye:0];
	[command exit];
	[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
}

- (void)getFcmDataAsync:(Account *)account {
	for (;;) {
		[self performSelectorOnMainThread:@selector(getFcmToken) withObject:nil waitUntilDone:YES];
		if (self.fcmToken)
			break;
		NSLog(@"waiting for FCM token...");
		sleep(1);
	}
	Cmd *command = [self login:account];
	[command setDeviceInfo:0 clientOS:@"iOS" osver:@"11.4" device:@"iPhone" fcmToken:self.fcmToken extra:@""];
	if ([command fcmDataRequest:0])
		[self applyFcmData:command.rawCmd.data forAccount:account];
	[self disconnect:account withCommand:command];
}

- (void)getTopicsAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command getTopicsRequest:0];
	unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
	int numRecords = (p[0] << 8) + p[1];
	p += 2;
	while (numRecords--) {
		int count = (p[0] << 8) + p[1];
		NSString *name = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
		int notificationType = p[2 + count];
		p += 3 + count;
		[account.topicList addObject:name];
	}
	[self disconnect:account withCommand:command];
}

- (void)getFcmDataForAccount:(Account *)account {
	account.error = nil;
	dispatch_async(self.serialQueue, ^{[self getFcmDataAsync:account];});
}

- (void)getTopicsForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getTopicsAsync:account];});
}

@end
