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
		if ([FIRApp defaultApp] == nil) {
			[FIRApp configureWithOptions:firOptions];
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
	return command;
}

- (Cmd *)login:(Account *)account {
	return [self login:account withMqttPassword:account.mqttPassword];
}

- (void)disconnect:(Account *)account withCommand:(Cmd *)command {
	account.error = command.rawCmd.error;
	[command bye:0];
	[command exit];
	[self performSelectorOnMainThread:@selector(postServerUpdateNotification) withObject:nil waitUntilDone:YES];
}

- (void)getFcmDataAsync:(Account *)account {
	Cmd *command = [self login:account];
	if ([command fcmDataRequest:0]) {
		[self applyFcmData:command.rawCmd.data forAccount:account];
	}
	for (;;) {
		[self performSelectorOnMainThread:@selector(getFcmToken) withObject:nil waitUntilDone:YES];
		if (self.fcmToken)
			break;
		NSLog(@"waiting for FCM token...");
		sleep(1);
	}
	[command setDeviceInfo:0 clientOS:@"iOS" osver:@"11.4" device:@"iPhone" fcmToken:self.fcmToken extra:@""];
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
	[command getMessagesRequest:(account.cdaccount.lastMessageID + 1)
						   date:account.cdaccount.lastTimestamp id:0];
	if (!command.rawCmd.error) {
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int numRecords = (p[0] << 8) + p[1];
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
	[command addActionRequest:0 action:action];
	[self disconnect:account withCommand:command];
}

#pragma public methods

- (void)getFcmDataForAccount:(Account *)account {
	account.error = nil;
	dispatch_async(self.serialQueue, ^{[self getFcmDataAsync:account];});
}

- (void)getMessagesForAccount:(Account *)account {
	dispatch_async(self.serialQueue, ^{[self getMessagesAsync:account];});
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

- (void)publishMessageForAccount:(Account *)account action:(Action *)action {
	dispatch_async(self.serialQueue, ^{[self publishMessageAsync:account action:action];});
}

- (void)addActionForAccount:(Account *)account action:(Action *)action {
	dispatch_async(self.serialQueue, ^{[self addActionAsync:account action:action];});
}

- (void)updateActionForAccount:(Account *)account action:(Action *)action name:(NSString *)name {
	dispatch_async(self.serialQueue, ^{[self addActionAsync:account action:action];});
}

@end
