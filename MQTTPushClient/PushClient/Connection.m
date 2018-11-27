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
#import "Action.h"
#import "Cmd.h"
#import "Topic.h"
#import "Action.h"
#import "Connection.h"
#import "AccountList.h"

enum ConnectionState {
	StateBusy,
	StateReady
};

@interface Connection()

@property dispatch_queue_t serialQueue;
@property NSString *fcmToken;
@property enum ConnectionState state;

@end

@implementation Connection

- (instancetype)init {
	self = [super init];
	if (self) {
		_serialQueue = dispatch_queue_create("connection.serial.queue", NULL);
		_fcmToken = nil;
		_state = StateReady;
	}
	return self;
}

- (void)postServerUpdateNotification {
	self.state = StateReady;
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
	dispatch_async(dispatch_get_main_queue(), ^{
		// pushServerID must be saved to user defaults, so that extension finds account.
		[[AccountList sharedAccountList] save];
		if ([FIRApp defaultApp] == nil) {
			@try {
				[FIRApp configureWithOptions:firOptions];
				UIApplication *app = [UIApplication sharedApplication];
				AppDelegate *appDelegate = (AppDelegate *)app.delegate;
				[appDelegate startMessaging];
			} @catch (NSException *exception) {
				NSLog(@"Could not configure FIRApp: %@", exception.reason);
			}
		}
	});
}

- (Cmd *)login:(Account *)account withMqttPassword:(NSString *)password {
	while (self.state == StateBusy)
		[NSThread sleepForTimeInterval:0.02f];
	int port = SERVER_DEFAULT_PORT;
	NSString *host = account.host;
	NSArray *array = [account.host componentsSeparatedByString:@":"];
	if ([array count] == 2) {
		host = array[0];
		NSString *portString = array[1];
		port = portString.intValue;
	}
	Cmd *command = [[Cmd alloc] initWithHost:host port:port];
	[command helloRequest:0 secureTransport:YES];
	[command loginRequest:0 uri:account.mqttURI user:account.mqttUser password:password];
	account.error = command.rawCmd.error;
	if (account.error)
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
	return command;
}

- (void)disconnect:(Account *)account withCommand:(Cmd *)command {
	account.error = command.rawCmd.error;
	[command bye:0];
	[command exit];
	[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
}

- (void)getFcmDataAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command fcmDataRequest:0];
	account.error = command.rawCmd.error;
	if (account.error) {
		[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
		return;
	}
	[self applyFcmData:command.rawCmd.data forAccount:account];
	for (;;) {
		[self performSelectorOnMainThread:@selector(getFcmToken) withObject:nil waitUntilDone:YES];
		if (self.fcmToken)
			break;
		NSLog(@"waiting for FCM token...");
		sleep(1);
	}
	NSString *iOSVersion = UIDevice.currentDevice.systemVersion;
	NSString *model = UIDevice.currentDevice.model;
	NSString *system = UIDevice.currentDevice.systemName;
	NSLocale *locale = [NSLocale currentLocale];
	NSInteger millisecondsFromGMT = 1000 * [[NSTimeZone localTimeZone] secondsFromGMT];
	[command setDeviceInfo:0 clientOS:system osver:iOSVersion device:model fcmToken:self.fcmToken locale:locale millisecondsFromGMT:millisecondsFromGMT extra:@""];
	[self disconnect:account withCommand:command];
}

- (void)removeTokenAsync:(Account *)account token:(NSString *)token {
	Cmd *command = [self login:account];
	[command removeTokenRequest:0 token:token];
	[self disconnect:account withCommand:command];
}

- (void)getTopicsAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command getTopicsRequest:0];
	if (!command.rawCmd.error) {
		[account.topicList removeAllObjects];
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		p += 2;
		while (numRecords--) {
			Topic *topic = [[Topic alloc] init];
			int count = (p[0] << 8) + p[1];
			topic.name = [[NSString alloc] initWithBytes:p + 2 length:count encoding:NSUTF8StringEncoding];
			topic.type = p[2 + count];
			p += 3 + count;
			[account.topicList addObject:topic];
		}
	}
	[self disconnect:account withCommand:command];
}

- (void)getMessagesAsync:(Account *)account {
	Cmd *command = [self login:account];
	// NSLog(@"getMessages after %d(%d)", (int)account.cdaccount.lastTimestamp.timeIntervalSince1970, account.cdaccount.lastMessageID);
	[command getMessagesRequest:0
						   date:account.cdaccount.lastTimestamp
							 id:account.cdaccount.lastMessageID];
	if (!command.rawCmd.error) {
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		// NSLog(@"getMessages: %d records", numRecords);
		NSMutableArray<Message *>*messageList = [NSMutableArray arrayWithCapacity:numRecords];
		p += 2;
		while (numRecords--) {
			Message *message = [[Message alloc] init];
			NSTimeInterval seconds = ((uint64_t)p[0] << 56) + ((uint64_t)p[1] << 48) + ((uint64_t)p[2] << 40) + ((uint64_t)p[3] << 32) + (p[4] << 24) + (p[5] << 16) + (p[6] << 8) + p[7];
			message.timestamp = [NSDate dateWithTimeIntervalSince1970:seconds];
			p += 8;
			int count = (p[0] << 8) + p[1];
			p += 2;
			message.topic = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			message.content = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			int msgID = (p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3];
			message.messageID = msgID;
			p += 4;
			[messageList addObject:message];
			// NSLog(@"    msg: %d(%d)", (int)seconds, msgID);
		}
		[account addMessageList:messageList];
	}
	[self disconnect:account withCommand:command];
}

- (void)addTopicAsync:(Account *)account name:(NSString *)name type:(enum NotificationType)type {
	Cmd *command = [self login:account];
	[command addTopicRequest:0 name:name type:type];
	[self disconnect:account withCommand:command];
}

- (void)updateTopicAsync:(Account *)account name:(NSString *)name type:(enum NotificationType)type {
	Cmd *command = [self login:account];
	[command updateTopicRequest:0 name:name type:type];
	[self disconnect:account withCommand:command];
}

- (void)deleteTopicAsync:(Account *)account name:(NSString *)name {
	Cmd *command = [self login:account];
	[command deleteTopicRequest:0 name:name];
	[self disconnect:account withCommand:command];
}

- (void)getActionsAsync:(Account *)account {
	Cmd *command = [self login:account];
	[command getActionsRequest:0];
	if (!command.rawCmd.error) {
		[account.actionList removeAllObjects];
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
		p += 2;
		while (numRecords--) {
			Action *action = [[Action alloc] init];
			int count = (p[0] << 8) + p[1];
			p += 2;
			action.name = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			action.topic = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			count = (p[0] << 8) + p[1];
			p += 2;
			action.content = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
			p += count;
			action.retainFlag = p[0];
			p++;
			[account.actionList addObject:action];
		}
	}
	[self disconnect:account withCommand:command];
}

- (void)publishMessageAsync:(Account *)account action:(Action *)action {
	Cmd *command = [self login:account];
	[command mqttPublishRequest:0 topic:action.topic content:action.content retainFlag:action.retainFlag];
	[self disconnect:account withCommand:command];
}

- (void)addActionAsync:(Account *)account action:(Action *)action {
	Cmd *command = [self login:account];
	[command addActionRequest:0 action:action];
	[self disconnect:account withCommand:command];
}

- (void)updateActionAsync:(Account *)account action:(Action *)action name:(NSString *)name {
	Cmd *command = [self login:account];
	[command updateActionRequest:0 action:action name:name];
	[self disconnect:account withCommand:command];
}

- (void)deleteActionAsync:(Account *)account name:(NSString *)name {
	Cmd *command = [self login:account];
	[command deleteActionRequest:0 name:name];
	[self disconnect:account withCommand:command];
}

#pragma mark - public methods

- (Cmd *)login:(Account *)account {
	return [self login:account withMqttPassword:account.mqttPassword];
}

- (void)getFcmDataForAccount:(Account *)account {
	account.error = nil;
	dispatch_async(self.serialQueue, ^{[self getFcmDataAsync:account];});
}

- (void)removeTokenForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self removeTokenAsync:account token:self.fcmToken];});
}

- (void)getMessagesForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getMessagesAsync:account];});
}

- (void)publishMessageForAccount:(Account *)account action:(Action *)action {
	dispatch_async(self.serialQueue, ^{[self publishMessageAsync:account action:action];});
}

- (void)getTopicsForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getTopicsAsync:account];});
}

- (void)addTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type {
	dispatch_async(self.serialQueue, ^{[self addTopicAsync:account name:name type:type];});
}

- (void)updateTopicForAccount:(Account *)account name:(NSString *)name type:(enum NotificationType)type {
	dispatch_async(self.serialQueue, ^{[self updateTopicAsync:account name:name type:type];});
}

- (void)deleteTopicForAccount:(Account *)account name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self deleteTopicAsync:account name:name];});
}

- (void)getActionsForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getActionsAsync:account];});
}

- (void)addActionForAccount:(Account *)account action:(Action *)action {
	dispatch_async(self.serialQueue, ^{[self addActionAsync:account action:action];});
}

- (void)updateActionForAccount:(Account *)account action:(Action *)action name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self updateActionAsync:account action:action name:name];});
}

- (void)deleteActionForAccount:(Account *)account name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self deleteActionAsync:account name:name];});
}

@end
