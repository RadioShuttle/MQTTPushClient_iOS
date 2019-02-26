/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
@import CoreData;
#import "CDAccount+CoreDataProperties.h"

#define SERVER_DEFAULT_PORT 2033

NS_ASSUME_NONNULL_BEGIN

@interface Account : NSObject

@property(readonly) NSString *host;		// host:port
@property(readonly) NSString *mqttHost;
@property(readonly) int mqttPort;
@property(readonly) NSString *mqttUser;
@property(readonly) BOOL mqttSecureTransport;
@property(readonly) NSString *uuid;
@property(nullable) NSString *pushServerID;

// Stored in Keychain:
@property(nullable) NSString *mqttPassword;

@property(readonly) NSString *mqttURI;
@property(readonly) NSString *accountID; // As sent by the server
@property(readonly) NSString *accountDescription; // For presentation, e.g. in table headers

// Runtime properties which are stored in memory only:
@property (readonly) NSURL *cacheURL; // Cache directory for this account
@property NSMutableArray *topicList;
@property NSMutableArray *actionList;
@property(nullable) NSError *error;
@property BOOL secureTransportToPushServer;
@property NSDate *secureTransportToPushServerDateSet; // Date when the above property was set to NO
@property(copy) NSString *fcmToken;

// Core Data related properties:
@property (readonly) NSManagedObjectContext *context;
@property (readonly) NSManagedObjectContext *backgroundContext;
@property(readonly) CDAccount *cdaccount;


+ (instancetype)accountWithHost:(NSString *)host
					   mqttHost:(NSString *)mqttHost
					   mqttPort:(int)mqttPort
			mqttSecureTransport:(BOOL)mqttSecureTransport
					   mqttUser:(nullable NSString *)mqttUser
						   uuid:(nullable NSString *)uuid;

- (BOOL)configure;
- (void)clearCache;
- (void)addMessageList:(NSArray<Message *>*)messageList updateSyncDate:(BOOL)updateSyncDate;
- (void)deleteMessagesBefore:(nullable NSDate *)before; // Pass `nil` to delete all messages
- (void)restoreMessages;

// Reading from and writing to user defaults:
+ (nullable instancetype)accountFromUserDefaultsDict:(NSDictionary *)dict;
- (NSDictionary *)userDefaultsDict;

@end

NS_ASSUME_NONNULL_END
