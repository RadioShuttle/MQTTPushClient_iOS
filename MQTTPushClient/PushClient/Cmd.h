/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Topic.h"

#define SecureTransportError 1550

enum ReturnCode {
	RC_OK = 0,
	RC_INVALID_ARGS = 400,
	RC_NOT_AUTHORIZED = 401,
	RC_INVALID_PROTOCOL = 403,
	RC_SERVER_ERROR = 500,
	RC_MQTT_ERROR = 503
};

@interface RawCmd : NSObject

@property int command;
@property int seqNo;
@property int flags;
@property int rc;
@property NSMutableData *header;
@property NSMutableData *data;
@property int numberOfBytesReceived;
@property NSError *error;

@end

@interface Cmd : NSObject

@property RawCmd *rawCmd;
@property int protocolMajor;
@property int protocolMinor;

- (instancetype)initWithHost:(NSString *)host port:(int)port;
- (void)exit;
- (RawCmd *)helloRequest:(int)seqNo secureTransport:(BOOL)secureTransport;
- (void)bye:(int)seqNo;
- (RawCmd *)loginRequest:(int)seqNo uri:(NSString *)uri user:(NSString *)user password:(NSString *)password;
- (RawCmd *)removeDeviceRequest:(int)seqNo;
- (RawCmd *)fcmDataRequest:(int)seqNo;
- (RawCmd *)getMessagesRequest:(int)seqNo date:(NSDate *)date id:(NSUInteger)messageID;
- (RawCmd *)getTopicsRequest:(int)seqNo;
- (RawCmd *)addTopicRequest:(int)seqNo name:(NSString *)name type:(enum NotificationType)type
			   filterScript:(NSString *)filterScript ;
- (RawCmd *)deleteTopicRequest:(int)seqNo name:(NSString *)name;
- (RawCmd *)updateTopicRequest:(int)seqNo name:(NSString *)name type:(enum NotificationType)type
				  filterScript:(NSString *)filterScript;
- (RawCmd *)setDeviceInfo:(int)seqNo clientOS:(NSString *)clientOS osver:(NSString *)osver device:(NSString *)device fcmToken:(NSString *)fcmToken locale:(NSLocale *)locale millisecondsFromGMT:(NSInteger)millisecondsFromGMT extra:(NSString *)extra;
- (RawCmd *)getActionsRequest:(int)seqNo;
- (RawCmd *)mqttPublishRequest:(int)seqNo topic:(NSString *)topic content:(NSData *)content retainFlag:(BOOL)retainFlag;
- (RawCmd *)addActionRequest:(int)seqNo action:(Action *)action;
- (RawCmd *)updateActionRequest:(int)seqNo action:(Action *)action name:(NSString *)name;
- (RawCmd *)deleteActionRequest:(int)seqNo name:(NSString *)name;
- (RawCmd *)getDashboardRequest:(int)seqNo;
- (RawCmd *)getDashMessagesRequest:(int)seqNo date:(uint64_t)unix_date id:(uint32_t)messageID;
- (RawCmd *)getResourceRequest:(int)seqNo name:(NSString *)name type:(NSString *)type;
- (RawCmd *)setDashboard:(int)seqNo version:(uint64_t)version itemID:(uint32_t)itemID dashboard:(NSData *)dashboard;
@end
