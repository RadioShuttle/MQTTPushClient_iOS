/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "GCDAsyncSocket.h"
#import "FCMData.h"
#import "Cmd.h"

#define MAGIC "MQTP"
#define PROTOCOL_MAJOR 1
#define PROTOCOL_MINOR 0
#define MAGIC_SIZE 4
#define HEADER_SIZE 12

enum Command {
	CMD_HELLO = 1,
	CMD_LOGIN = 2,
	CMD_GET_FCM_DATA = 3,
	CMD_GET_SUBSCR = 4,
	CMD_SUBSCRIBE = 5,
	CMD_UNSUBSCRIBE = 6,
	CMD_UPDATE_TOPICS = 7,
	CMD_SET_DEVICE_INFO = 8,
	CMD_REMOVE_TOKEN = 9,
	CMD_GET_ACTIONS = 10,
	CMD_ADD_ACTION = 11,
	CMD_UPDATE_ACTION = 12,
	CMD_REMOVE_ACTIONS = 13,
	CMD_LOGOUT = 14,
	CMD_BYE = 15,
	CMD_PUBLISH = 17
};

enum ReturnCode {
	RC_OK = 0,
	RC_INVALID_ARGS = 400,
	RC_NOT_AUTHORIZED = 401,
	RC_INVALID_PROTOCOL = 403,
	RC_SERVER_ERROR = 500,
	RC_MQTT_ERROR = 503
};

enum TransmissionFlag {
	FLAG_REQUEST,
	FLAG_RESPONSE
};

enum StateProtocol {
	ProtocolStateHeaderWritten = 420,
	ProtocolStateContentWritten,
	ProtocolStateMagicReceived = 780,
	ProtocolStateHeaderReceived,
	ProtocolStateDataReceived,
	ProtocolStateEnd
};

@interface RawCmd()

@end

@implementation RawCmd

- (instancetype)init {
	self = [super init];
	if (self) {
		_seqNo = 9200;
		_data = [[NSMutableData alloc] initWithLength:4000];
	}
	return self;
}

@end

@interface Cmd() <GCDAsyncSocketDelegate>

@property NSLock *lock;
@property GCDAsyncSocket *socket;
@property NSTimeInterval timeout;
- (instancetype)initWithHost:(NSString *)host port:(int)port;

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
		_state = CommandStateConnect;
		_lock = [[NSLock alloc] init];
		_timeout = 2.1;
		_socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
		if ([self.socket connectToHost:host onPort:port withTimeout:0.3 error:&error])
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
	[self.socket readDataToLength:MAGIC_SIZE withTimeout:self.timeout buffer:self.rawCmd.data bufferOffset:0 tag:ProtocolStateMagicReceived];
	[self.socket readDataToLength:HEADER_SIZE withTimeout:self.timeout buffer:self.rawCmd.data bufferOffset:MAGIC_SIZE tag:ProtocolStateHeaderReceived];
	self.rawCmd.seqNo++;
	return self.rawCmd;
}

- (void)writeCommand:(int)cmd seqNo:(int)seqNo flags:(int)flags rc:(int)rc data:(NSData *)data {
	self.rawCmd.seqNo = seqNo;
	[self writeHeader:cmd seqNo:seqNo flags:flags rc:rc contentSize:data.length];
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

- (RawCmd *)helloRequest:(int)seqNo {
	unsigned char protocol[] = {PROTOCOL_MAJOR, PROTOCOL_MINOR};
	NSData *data = [NSData dataWithBytes:protocol length:2];
	[self writeCommand:CMD_HELLO seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	return [self readCommand];
}

- (RawCmd *)loginRequest:(int)seqNo uri:(NSString *)uri user:(NSString *)user password:(NSString *)password {
	NSMutableData *data = [self dataFromString:uri encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:user encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:password encoding:NSUTF16BigEndianStringEncoding]];
	[self writeCommand:CMD_LOGIN seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	return [self readCommand];
}

- (RawCmd *)fcmDataRequest:(int)seqNo {
	return [self request:CMD_GET_FCM_DATA seqNo:seqNo];
}

- (RawCmd *)setDeviceInfo:(int)seqNo clientOS:(NSString *)clientOS osver:(NSString *)osver device:(NSString *)device fcmToken:(NSString *)fcmToken extra:(NSString *)extra {
	NSMutableData *data = [self dataFromString:clientOS encoding:NSUTF8StringEncoding];
	[data appendData:[self dataFromString:osver encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:device encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:fcmToken encoding:NSUTF8StringEncoding]];
	[data appendData:[self dataFromString:extra encoding:NSUTF8StringEncoding]];
	[self writeCommand:CMD_SET_DEVICE_INFO seqNo:seqNo flags:FLAG_REQUEST rc:0 data:data];
	return [self readCommand];
}

- (void)setNextState {
	switch (self.state) {
		case CommandStateError:
			self.state = CommandStateEnd;
			break;
		case CommandStateHello:
			self.state = CommandStateLogin;
			break;
		case CommandStateLogin:
			self.state = CommandStateGetFCMData;
			break;
		case CommandStateGetFCMData:
			self.state = CommandStateSetDeviceInfo;
			break;
		case CommandStateSetDeviceInfo:
			self.state = CommandStateEnd;
			break;
		default:
			self.state = CommandStateEnd;
			break;
	}
}

# pragma - socket delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	NSLog(@"connected to: %@ port: %d", host, port);
	self.state = CommandStateHello;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
	NSLog(@"disconnected: %@", error);
	self.state = CommandStateEnd;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"data received (tag:%ld)", tag);
	char *text;
	unsigned char *dp;
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
			dp = (unsigned char *)self.rawCmd.data.bytes;
			dp += MAGIC_SIZE;
			self.rawCmd.command = (dp[0] << 8) + (dp[1] & 0xff);
			self.rawCmd.seqNo = (dp[2] << 8) + (dp[3] & 0xff);
			self.rawCmd.flags = (dp[4] << 8) + (dp[5] & 0xff);
			self.rawCmd.rc = (dp[6] << 8) + (dp[7] & 0xff);
			self.rawCmd.dataLength = (dp[8] << 24) + (dp[9] << 16) + (dp[10] << 8) + (dp[11] & 0xff);
			NSLog(@"header: cmd=%d seqNo=%d flags=%d rc=%d", self.rawCmd.command, self.rawCmd.seqNo, self.rawCmd.flags, self.rawCmd.rc);
			NSLog(@"data length: %d", self.rawCmd.dataLength);
			if (self.rawCmd.dataLength)
				[self.socket readDataToLength:self.rawCmd.dataLength withTimeout:self.timeout buffer:self.rawCmd.data bufferOffset:0 tag:ProtocolStateDataReceived];
			else
				[self setNextState];
			break;
		case ProtocolStateDataReceived:
			dp = (unsigned char *)self.rawCmd.data.bytes;
			self.rawCmd.data = [NSMutableData dataWithBytes:dp length:self.rawCmd.dataLength];
			[self setNextState];
			break;
		default:
			self.state = CommandStateEnd;
			break;
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"data written (tag:%ld)", tag);
}

@end
