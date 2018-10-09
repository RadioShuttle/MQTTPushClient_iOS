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

- (void)cleanUp {
}

- (void)getFcmToken {
	UIApplication *app = [UIApplication sharedApplication];
	AppDelegate *appDelegate = (AppDelegate *)app.delegate;
	self.fcmToken = appDelegate.fcmToken;
}

- (void)notifyUI {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self];
}

- (void)decodeFcmData:(NSData *)data {
	FCMData *fcmData = [[FCMData alloc] init];
	unsigned char *p = (unsigned char *)data.bytes;
	int count = (p[0] << 8) + p[1];
	fcmData.app_id = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.api_key = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	p += 2 + count;
	count = (p[0] << 8) + p[1];
	fcmData.pushserverid = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
	NSString *file = [NSBundle.mainBundle pathForResource:@"GoogleService-Info" ofType:@"plist"];
	FIROptions *firOptions = [[FIROptions alloc] initWithContentsOfFile:file];
	firOptions.APIKey = fcmData.api_key;
	firOptions.googleAppID = fcmData.app_id;
	NSString *name = fcmData.pushserverid;
	NSArray *array = [name componentsSeparatedByString:@":"];
	if ([array count] == 2)
		name = array[0];
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	[FIRApp configureWithName:appName options:firOptions];
}

- (void)contactServerWith:(Account *)account {
	for (;;) {
		[self performSelectorOnMainThread:@selector(getFcmToken) withObject:nil waitUntilDone:YES];
		if (self.fcmToken)
			break;
		NSLog(@"waiting for FCM token...");
		sleep(1);
	}
	int port = SERVER_DEFAULT_PORT;
	NSString *host = account.host;
	NSArray *array = [account.host componentsSeparatedByString:@":"];
	if ([array count] == 2) {
		host = array[0];
		NSString *portString = array[1];
		port = portString.intValue;
	}
	Cmd *command = [[Cmd alloc] initWithHost:host port:port];
	if (command) {
		NSString *string;
		[command helloRequest:0];
		if (account.mqtt.secureTransport)
			string = [NSString stringWithFormat:@"ssl://%@:%@", account.mqtt.host, account.mqtt.port];
		else
			string = [NSString stringWithFormat:@"tcp://%@:%@", account.mqtt.host, account.mqtt.port];
		[command loginRequest:0 uri:string user:account.mqtt.user password:account.mqtt.password];
		[command setDeviceInfo:0 clientOS:@"iOS" osver:@"11.4" device:@"iPhone" fcmToken:self.fcmToken extra:@""];
		if ([command fcmDataRequest:0]) {
			[self decodeFcmData:command.rawCmd.data];
			account.connectionEstablished = YES;
			[self performSelectorOnMainThread:@selector(notifyUI) withObject:nil waitUntilDone:YES];
		}
		[command exit];
	}
	[self performSelectorOnMainThread:@selector(cleanUp) withObject:nil waitUntilDone:YES];
}

- (void)getFcmDataForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self contactServerWith:account];});
}

@end
