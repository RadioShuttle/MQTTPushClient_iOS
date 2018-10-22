/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import <Foundation/Foundation.h>

@interface RawCmd : NSObject

@property int command;
@property int seqNo;
@property int flags;
@property int rc;
@property NSMutableData *header;
@property NSMutableData *data;
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
- (RawCmd *)fcmDataRequest:(int)seqNo;
- (RawCmd *)getTopicsRequest:(int)seqNo;
- (RawCmd *)setDeviceInfo:(int)seqNo clientOS:(NSString *)clientOS osver:(NSString *)osver device:(NSString *)device fcmToken:(NSString *)fcmToken extra:(NSString *)extra;

@end
