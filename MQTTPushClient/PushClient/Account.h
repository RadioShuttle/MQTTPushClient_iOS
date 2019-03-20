/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
#ifndef MQTT_EXTENSION
@import CoreData;
#import "CDAccount+CoreDataProperties.h"
#endif
#define SERVER_DEFAULT_PORT 2033

NS_ASSUME_NONNULL_BEGIN

@class Topic, Action;

@interface Account : NSObject

+ (instancetype)accountWithHost:(NSString *)host
					   mqttHost:(NSString *)mqttHost
					   mqttPort:(int)mqttPort
			mqttSecureTransport:(BOOL)mqttSecureTransport
					   mqttUser:(nullable NSString *)mqttUser
						   uuid:(nullable NSString *)uuid;

@property(readonly) NSString *host;		// host:port
@property(readonly) NSString *mqttHost;
@property(readonly) int mqttPort;
@property(readonly) NSString *mqttUser;
@property(readonly) BOOL mqttSecureTransport;
@property(readonly) NSString *uuid;
@property(nullable, copy) NSString *pushServerID;

@property(readonly) NSString *mqttURI;
@property(readonly) NSString *accountID; // As sent by the server
@property(readonly) NSString *accountDescription; // For presentation, e.g. in table headers

// Runtime properties which are stored in memory only:
@property (copy) NSArray<Topic *> *topicList;
@property (copy) NSArray<Action *> *actionList;
@property BOOL secureTransportToPushServer;
@property NSDate *secureTransportToPushServerDateSet; // Date when the above property was set to NO

// Reading from and writing to user defaults:
+ (nullable instancetype)accountFromUserDefaultsDict:(NSDictionary *)dict;
- (NSDictionary *)userDefaultsDict;

- (nullable Topic *)topicWithName:(NSString *)topicName;

#ifndef MQTT_EXTENSION

// Stored in Keychain:
@property(nullable, copy) NSString *mqttPassword;

// Runtime properties which are stored in memory only:
@property (readonly) NSURL *cacheURL; // Cache directory for this account
@property(nullable) NSError *error;
@property(copy, nullable) NSString *fcmSenderID;
@property(copy) NSString *fcmToken;


// Core Data related properties:
@property (readonly) NSManagedObjectContext *context;
@property (readonly) NSManagedObjectContext *backgroundContext;
@property(readonly) CDAccount *cdaccount;


- (BOOL)configure;
- (void)clearCache;
- (void)addMessageList:(NSArray<Message *>*)messageList updateSyncDate:(BOOL)updateSyncDate;
- (void)deleteMessagesBefore:(nullable NSDate *)before; // Pass `nil` to delete all messages
- (void)restoreMessages;
#endif

@end

NS_ASSUME_NONNULL_END
