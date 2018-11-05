/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
@import CoreData;
#import "CDAccount+CoreDataProperties.h"

#define SERVER_DEFAULT_PORT 2033
#define MQTT_DEFAULT_PORT 1883
#define MQTT_SECURE_PORT 8883

NS_ASSUME_NONNULL_BEGIN

@interface Account : NSObject

@property(readonly) NSString *host;		// Push server (host:port)
@property(readonly) NSString *mqttHost; // MQTT Server (host:port)
@property(readonly) NSString *mqttUser;
@property(readonly) BOOL mqttSecureTransport;
@property(readonly) NSString *uuid;
@property(nullable) NSString *pushServerID;

// Stored in Keychain:
@property(nullable) NSString *mqttPassword;

@property(readonly) NSString *mqttURI;

// Runtime properties which are stored in memory only:
@property (readonly) NSURL *cacheURL; // Cache directory for this account
@property NSMutableArray *topicList;
@property(nullable) NSError *error;

// Core Data related properties:
@property (readonly) NSManagedObjectContext *context;
@property (readonly) NSManagedObjectContext *backgroundContext;
@property(readonly) CDAccount *cdaccount;


+ (instancetype)accountWithHost:(NSString *)host
								mqttHost:(NSString *)mqttHost
					 mqttSecureTransport:(BOOL)mqttSecureTransport
								mqttUser:(NSString *)mqttUser
									uuid:(nullable NSString *)uuid;

- (BOOL)configure;
- (void)clearCache;
- (void)addMessageList:(NSArray<Message *>*)messageList;

// Reading from and writing to user defaults:
+ (nullable instancetype)accountFromUserDefaultsDict:(NSDictionary *)dict;
- (NSDictionary *)userDefaultsDict;

@end

NS_ASSUME_NONNULL_END
