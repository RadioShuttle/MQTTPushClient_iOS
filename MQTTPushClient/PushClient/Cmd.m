/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "GCDAsyncSocket.h"
#import "FCMData.h"
#import "Action.h"
#import "Cmd.h"

#define MAGIC "MQTP"
#define PROTOCOL_MAJOR 1
#define PROTOCOL_MINOR 4
#define MAGIC_SIZE 4
#define HEADER_SIZE 12

enum Command {
	CMD_HELLO = 1,
	CMD_LOGIN = 2,
	CMD_GET_FCM_DATA = 3,
	CMD_GET_TOPICS = 4,
	CMD_ADD_TOPICS = 5,
	CMD_DEL_TOPICS = 6,
	CMD_UPD_TOPICS = 7,
	CMD_SET_DEVICE_INFO = 8,
	CMD_REMOVE_TOKEN = 9,
	CMD_GET_ACTIONS = 10,
	CMD_ADD_ACTION = 11,
	CMD_UPD_ACTION = 12,
	CMD_DEL_ACTIONS = 13,
	CMD_LOGOUT = 14,
	CMD_DISCONNECT = 15,
	CMD_MQTT_PUBLISH = 17,
	CMD_GET_FCM_DATA_IOS = 18,
	CMD_GET_MESSAGES = 19,
	CMD_ADM = 20
};

enum TransmissionFlag {
	FLAG_REQUEST = 0,
	FLAG_RESPONSE = 1,
	FLAG_SSL = 2,
	FLAG_ADM =4
};

enum StateProtocol {
	ProtocolStateHeaderWritten = 420,
	ProtocolStateContentWritten,
	ProtocolStateMagicReceived = 780,
	ProtocolStateHeaderReceived,
	ProtocolStateDataReceived,
	ProtocolStateEnd
};

enum StateCommand {
	CommandStateBusy,
	CommandStateDone,
	CommandStateEnd
};

@interface RawCmd()

@end

@implementation RawCmd

- (instancetype)init {
	self = [super init];
	if (self) {
		_seqNo = 9200;
		_header = [[NSMutableData alloc] initWithLength:MAGIC_SIZE + HEADER_SIZE];
		_data = [[NSMutableData alloc] initWithLength:4000];
		_numberOfBytesReceived = 0;
	}
	return self;
}

@end

@interface Cmd() <GCDAsyncSocketDelegate>

@property NSLock *lock;
@property GCDAsyncSocket *socket;
@property NSTimeInterval timeout;
@property enum StateCommand state;

@end

@implementation Cmd

@synthesize state = _state;

- (enum StateCommand)state {
	enum StateCommand value;
	[self.lock lock];
	value = _state;
	[self.lock unlock];
	return value;
}

- (void)setState:(enum StateCommand)state {
	[self.lock lock];
	_state = state;
	[self.lock unlock];
}

- (instancetype)initWithHost:(NSString *)host port:(int)port {
	self = [super init];
	if (self) {
		NSError *error = nil;
		_state = CommandStateBusy;
		_lock = [[NSLock alloc] init];
		_timeout = 10;
		_protocolMajor = PROTOCOL_MAJOR;
		_protocolMinor = PROTOCOL_MINOR;
		_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		if ([self.socket connectToHost:host onPort:port withTimeout:_timeout error:&error])
			_rawCmd = [[RawCmd alloc] init];
		else
			return nil;
	}
	NSLog(@"socket opened");
	return self;
}

- (void)exit {
	[self.socket disconnectAfterReadingAndWriting];
	NSLog(@"socket closed");
}

- (void)writeHeader:(int)cmd seqNo:(int)seqNo flags:(int)flags rc:(int)rc contentSize:(NSUInteger)contentSize {
	unsigned char buffer[4];
	size_t len = strlen(MAGIC);
	NSMutableData *data = [[NSMutableData alloc] init];
	[data appendBytes:MAGIC length:len];
	buffer[0] = cmd >> 8;
	buffer[1] = cmd & 0xff;
	[data appendBytes:buffer length:2];
	buffer[0] = seqNo >> 8;
	buffer[1] = seqNo & 0xff;
	[data appendBytes:buffer length:2];
	buffer[0] = flags >> 8;
	buffer[1] = flags & 0xff;
	[data appendBytes:buffer length:2];
	buffer[0] = rc >> 8;
	buffer[1] = rc & 0xff;
	[data appendBytes:buffer length:2];
	buffer[0] = contentSize >> 24;
	buffer[1] = contentSize >> 16;
	buffer[2] = contentSize >> 8;
	buffer[3] = contentSize & 0xff;
	[data appendBytes:buffer length:4];
	[self.socket writeData:data withTimeout:self.timeout tag:ProtocolStateHeaderWritten];
}

- (void)writeContent:(NSData *)data {
	[self.socket writeData:data withTimeout:self.timeout tag:ProtocolStateContentWritten];
}

- (RawCmd *)readCommand {
	[self.socket readDataToLength:MAGIC_SIZE withTimeout:self.timeout buffer:self.rawCmd.header bufferOffset:0 tag:ProtocolStateMagicReceived];
	[self.socket readDataToLength:HEADER_SIZE withTimeout:self.timeout buffer:self.rawCmd.header bufferOffset:MAGIC_SIZE tag:ProtocolStateHeaderReceived];
	return self.rawCmd;
}

- (void)writeCommand:(int)cmd seqNo:(int)seqNo flags:(int)flags rc:(int)rc data:(NSData *)data {
	if (seqNo)
		self.rawCmd.seqNo = seqNo;
	else
		self.rawCmd.seqNo++;
	[self writeHeader:cmd seqNo:self.rawCmd.seqNo flags:flags rc:rc contentSize:data.length];
	[self writeContent:data];
}

- (RawCmd *)request:(int)cmd seqNo:(int)seqNo {
	NSData *data = [NSData data];
	[self writeCommand:cmd seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	return [self readCommand];
}

- (NSMutableData *)dataFromString:(NSString *)string encoding:(NSStringEncoding)encoding {
	NSData *dataString = [string dataUsingEncoding:encoding];
	NSUInteger count = dataString.length;
	if (encoding == NSUTF16BigEndianStringEncoding)
		count = string.length;
	unsigned char buffer[] = {count >> 8, count & 0xff};
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:2];
	[data appendData:dataString];
	return data;
}

- (void)waitForCommand {
	while (self.state == CommandStateBusy)
		[NSThread sleepForTimeInterval:0.02f];
	if (self.state != CommandStateEnd)
		self.state = CommandStateBusy;
}

- (RawCmd *)helloRequest:(int)seqNo secureTransport:(BOOL)secureTransport {
	if (self.state == CommandStateEnd)
		return nil;
	unsigned char protocol[2];
	protocol[0] = PROTOCOL_MAJOR;
	protocol[1] = PROTOCOL_MINOR;
	NSData *data = [NSData dataWithBytes:protocol length:2];
	enum TransmissionFlag flag = FLAG_REQUEST;
	if (secureTransport) {
		flag |= FLAG_SSL;
	}
	[self writeCommand:CMD_HELLO seqNo:seqNo flags:flag rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	if (self.rawCmd.rc == RC_INVALID_PROTOCOL && self.rawCmd.numberOfBytesReceived == 2) {
		unsigned char *p = (unsigned char *)self.rawCmd.data.bytes;
		int protocolMajor = p[0];
		int protocolMinor = p[1];
		NSString *description = [NSString stringWithFormat:@"Server: %d.%d - Client: %d.%d (protocol mismatch)", protocolMajor, protocolMinor, PROTOCOL_MAJOR, PROTOCOL_MINOR];
		self.rawCmd.error = [[NSError alloc] initWithDomain:@"MQTT Protocol" code:RC_INVALID_PROTOCOL userInfo:@{NSLocalizedDescriptionKey:description}];
		return nil;
	}
	flag = self.rawCmd.flags;
	if (flag & FLAG_SSL) {
		NSDictionary *tlsSettings = @{
									  GCDAsyncSocketManuallyEvaluateTrust : @(YES),
									  };
		[self.socket startTLS:tlsSettings];
	}
	return self.rawCmd;
}

- (void)bye:(int)seqNo {
	if (self.state == CommandStateEnd)
		return;
	NSData *data = [[NSData alloc] init];
	[self writeCommand:CMD_DISCONNECT seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
 }
	 
- (RawCmd *)loginRequest:(int)seqNo uri:(NSString *)uri user:(NSString *)user password:(NSString *)password {
	if (self.state == CommandStateEnd)
		return nil;
	NSMutableData *data = [self dataFromString:uri encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:user encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:password encoding:NSUTF8StringEncoding]];
	[self writeCommand:CMD_LOGIN seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)removeTokenRequest:(int)seqNo token:(NSString *)token {
	if (self.state == CommandStateEnd)
		return nil;
	NSMutableData *data = [self dataFromString:token encoding:NSUTF8StringEncoding];
	[self writeCommand:CMD_REMOVE_TOKEN seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)fcmDataRequest:(int)seqNo {
	if (self.state == CommandStateEnd)
		return nil;
	[self request:CMD_GET_FCM_DATA_IOS seqNo:seqNo];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)getMessagesRequest:(int)seqNo date:(NSDate *)date id:(NSUInteger)messageID {
	if (self.state == CommandStateEnd)
		return nil;
	NSInteger seconds = [date timeIntervalSince1970];
	unsigned char buffer[8];
	buffer[7] = seconds & 0xff;;
	buffer[6] = seconds >> 8;
	buffer[5] = seconds >> 16;
	buffer[4] = seconds >> 24;
	buffer[3] = seconds >> 32;
	buffer[2] = seconds >> 40;
	buffer[1] = seconds >> 48;
	buffer[0] = seconds >> 56;
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:8];
	buffer[3] = messageID & 0xff;;
	buffer[2] = messageID >> 8;
	buffer[1] = messageID >> 16;
	buffer[0] = messageID >> 24;
	[data appendBytes:buffer length:4];
	[self writeCommand:CMD_GET_MESSAGES seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)getTopicsRequest:(int)seqNo {
	if (self.state == CommandStateEnd)
		return nil;
	[self request:CMD_GET_TOPICS seqNo:seqNo];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)addTopicRequest:(int)seqNo name:(NSString *)name type:(enum NotificationType)type {
	if (self.state == CommandStateEnd)
		return nil;
	unsigned char buffer[2];
	buffer[0] = 0;
	buffer[1] = 1;
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:2];
	[data appendData:[self dataFromString:name encoding:NSUTF8StringEncoding]];
	buffer[0] = type;
	[data appendBytes:buffer length:1];
	[self writeCommand:CMD_ADD_TOPICS seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)deleteTopicRequest:(int)seqNo name:(NSString *)name {
	if (self.state == CommandStateEnd)
		return nil;
	unsigned char buffer[2];
	buffer[0] = 0;
	buffer[1] = 1;
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:2];
	[data appendData:[self dataFromString:name encoding:NSUTF8StringEncoding]];
	[self writeCommand:CMD_DEL_TOPICS seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)updateTopicRequest:(int)seqNo name:(NSString *)name type:(enum NotificationType)type {
	if (self.state == CommandStateEnd)
		return nil;
	unsigned char buffer[2];
	buffer[0] = 0;
	buffer[1] = 1;
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:2];
	[data appendData:[self dataFromString:name encoding:NSUTF8StringEncoding]];
	buffer[0] = type;
	[data appendBytes:buffer length:1];
	[self writeCommand:CMD_UPD_TOPICS seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)setDeviceInfo:(int)seqNo clientOS:(NSString *)clientOS osver:(NSString *)osver device:(NSString *)device fcmToken:(NSString *)fcmToken locale:(NSLocale *)locale millisecondsFromGMT:(NSInteger)millisecondsFromGMT extra:(NSString *)extra {
	if (self.state == CommandStateEnd)
		return nil;
	NSString *country = locale.countryCode;
	NSString *language = locale.languageCode;
	unsigned char buffer[4];
	buffer[3] = millisecondsFromGMT & 0xff;;
	buffer[2] = millisecondsFromGMT >> 8;
	buffer[1] = millisecondsFromGMT >> 16;
	buffer[0] = millisecondsFromGMT >> 24;
	NSMutableData *data = [self dataFromString:clientOS encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:osver encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:device encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:fcmToken encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:country encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:language encoding:NSUTF8StringEncoding]];
	[data appendBytes:buffer length:4];
	[data appendData:[self dataFromString:extra encoding:NSUTF8StringEncoding]];
	[self writeCommand:CMD_SET_DEVICE_INFO seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)getActionsRequest:(int)seqNo {
	if (self.state == CommandStateEnd)
		return nil;
	[self request:CMD_GET_ACTIONS seqNo:seqNo];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)mqttPublishRequest:(int)seqNo topic:(NSString *)topic content:(NSString *)content retainFlag:(BOOL)retainFlag {
	if (self.state == CommandStateEnd)
		return nil;
	NSMutableData *data = [self dataFromString:topic encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:content encoding:NSUTF8StringEncoding]];
	unsigned char buffer[1];
	buffer[0] = retainFlag;
	[data appendBytes:buffer length:1];
	[self writeCommand:CMD_MQTT_PUBLISH seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)addActionRequest:(int)seqNo action:(Action *)action {
	if (self.state == CommandStateEnd)
		return nil;
	NSMutableData *data = [self dataFromString:action.name encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:action.topic encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:action.content encoding:NSUTF8StringEncoding]];
	unsigned char buffer[1];
	buffer[0] = action.retainFlag;
	[data appendBytes:buffer length:1];
	[self writeCommand:CMD_ADD_ACTION seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)updateActionRequest:(int)seqNo action:(Action *)action name:(NSString *)name {
	if (self.state == CommandStateEnd)
		return nil;
	NSMutableData *data = [self dataFromString:action.name encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:name encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:action.topic encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:action.content encoding:NSUTF8StringEncoding]];
	unsigned char buffer[1];
	buffer[0] = action.retainFlag;
	[data appendBytes:buffer length:1];
	[self writeCommand:CMD_UPD_ACTION seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

- (RawCmd *)deleteActionRequest:(int)seqNo name:(NSString *)name {
	if (self.state == CommandStateEnd)
		return nil;
	unsigned char buffer[2];
	buffer[0] = 0;
	buffer[1] = 1;
	NSMutableData *data = [NSMutableData dataWithBytes:buffer length:2];
	[data appendData:[self dataFromString:name encoding:NSUTF8StringEncoding]];
	[self writeCommand:CMD_DEL_ACTIONS seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	[self readCommand];
	[self waitForCommand];
	return self.rawCmd;
}

# pragma - socket delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	NSLog(@"connected to: %@ port: %d", host, port);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
	NSLog(@"disconnected: %@", error ? error : @"normally");
	if (!self.rawCmd.error) {
		if ([error.domain isEqualToString:@"kCFStreamErrorDomainNetDB"] && error.code == 8) {
			NSString *description = @"Airplane mode might be active.";
			self.rawCmd.error = [[NSError alloc] initWithDomain:@"User Option" code:error.code userInfo:@{NSLocalizedDescriptionKey:description}];
		} else
			self.rawCmd.error = error;
	}
	self.state = CommandStateEnd;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"data received (tag:%ld)", tag);
	char *text;
	unsigned char *hp;
	enum StateProtocol protocol = (enum StateProtocol)tag;
	switch (protocol) {
		case ProtocolStateMagicReceived:
			text = (char *)data.bytes;
			if (strncmp(text, MAGIC, 4) != 0) {
				self.state = CommandStateEnd;
				NSLog(@"bad magic");
			}
			break;
		case ProtocolStateHeaderReceived:
			hp = (unsigned char *)self.rawCmd.header.bytes;
			hp += MAGIC_SIZE;
			self.rawCmd.command = (hp[0] << 8) + (hp[1] & 0xff);
			self.rawCmd.seqNo = (hp[2] << 8) + (hp[3] & 0xff);
			self.rawCmd.flags = (hp[4] << 8) + (hp[5] & 0xff);
			self.rawCmd.rc = (hp[6] << 8) + (hp[7] & 0xff);
			self.rawCmd.numberOfBytesReceived = (hp[8] << 24) + (hp[9] << 16) + (hp[10] << 8) + (hp[11] & 0xff);
			NSLog(@"header: cmd=%d seqNo=%d flags=%d rc=%d", self.rawCmd.command, self.rawCmd.seqNo, self.rawCmd.flags, self.rawCmd.rc);
			NSLog(@"data length: %d", self.rawCmd.numberOfBytesReceived);
			if (self.rawCmd.numberOfBytesReceived)
				[self.socket readDataToLength:self.rawCmd.numberOfBytesReceived withTimeout:self.timeout buffer:self.rawCmd.data bufferOffset:0 tag:ProtocolStateDataReceived];
			else
				self.state = CommandStateDone;
			break;
		case ProtocolStateDataReceived:
			self.state = CommandStateDone;
			break;
		default:
			self.state = CommandStateEnd;
			break;
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"data written (tag:%ld)", tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
	NSLog(@"socket:didReceiveTrust:");
	
	// Load "ca-certificate.der":
	static CFArrayRef trustedAnchors = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *certUrl = [[NSBundle mainBundle] URLForResource:@"ca-certificate" withExtension:@"der"];
		NSData *certData = [NSData dataWithContentsOfURL:certUrl];
		SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certData);
		if (cert != NULL) {
			trustedAnchors = CFArrayCreate(NULL, (void *)&cert, 1, &kCFTypeArrayCallBacks);
			CFRelease(cert);
		}
	});
	
	dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(bgQueue, ^{
		if (trustedAnchors != NULL) {
			SecTrustSetAnchorCertificates(trust, trustedAnchors);
			SecTrustSetAnchorCertificatesOnly(trust, false);
		}
		
		SecTrustResultType result = kSecTrustResultDeny;
		OSStatus status = SecTrustEvaluate(trust, &result);
		BOOL trusted = (status == noErr) && ((result == kSecTrustResultProceed || result == kSecTrustResultUnspecified));
		
		NSLog(@"socket:didReceiveTrust: trusted=%@, result=%d", @(trusted), result);
		if (trusted) {
			completionHandler(YES);
		} else {
			
			/*
			 TODO: Present warning for invalid certificate, and
			 allow user to accept or reject.
			 
			 Resources:
			 https://developer.apple.com/library/archive/technotes/tn2232/_index.html
			 https://github.com/robbiehanson/CocoaAsyncSocket/blob/master/Examples/GCD/SimpleHTTPClient/Mobile/SimpleHTTPClient/SimpleHTTPClientAppDelegate.m
			 */
			
			completionHandler(YES);
		}
	});
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
	NSLog(@"socketDidSecure:");
}

@end
