/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import UIKit;

#import "Account.h"
#import "KeychainUtils.h"
#import "SharedConstants.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Message.h"
#include <sys/stat.h>    // for mkdir()

static NSString *kPrefkeyHost = @"pushserver.host";
static NSString *kPrefkeyMqttHost = @"mqtt.host";
static NSString *kPrefkeyMqttPort = @"mqtt.port";
static NSString *kPrefkeyMqttSecureTransport = @"mqtt.securetransport";
static NSString *kPrefkeyMqttUser = @"mqtt.user";
static NSString *kPrefkeyUuid = @"uuid";
static NSString *kPrefkeyPushServerID = @"pushserver.id";

@interface Account ()

// Public read-only property are internally read-write:
@property(readwrite, copy) NSString *host;
@property(readwrite, copy) NSString *mqttHost;
@property(readwrite) int mqttPort;
@property(readwrite) BOOL mqttSecureTransport;
@property(readwrite, copy) NSString *mqttUser;
@property(readwrite, copy) NSString *uuid;
@property(readwrite, copy) NSURL *cacheURL;
@property(readwrite) NSManagedObjectContext *context;
@property(readwrite) NSManagedObjectContext *backgroundContext;
@property(readwrite) NSPersistentContainer *cdcontainer;
@property(readwrite) CDAccount *cdaccount;

@end

@implementation Account

+ (instancetype)accountWithHost:(NSString *)host
					   mqttHost:(NSString *)mqttHost
					   mqttPort:(int)mqttPort
			mqttSecureTransport:(BOOL)mqttSecureTransport
					   mqttUser:(NSString *)mqttUser
						   uuid:(nullable NSString *)uuid {
	
	Account *account = [[Account alloc] init];
	account.host = host;
	account.mqttHost = mqttHost;
	account.mqttPort = mqttPort;
	account.mqttSecureTransport = mqttSecureTransport;
	account.mqttUser = mqttUser ? mqttUser : @"";
	account.uuid = uuid;
	
	account.topicList = [NSMutableArray array];
	account.actionList = [NSMutableArray array];
	return account;
}

+ (nullable instancetype)accountFromUserDefaultsDict:(NSDictionary *)dict {
	NSString *host = [dict helStringForKey:kPrefkeyHost];
	NSString *mqttHost = [dict helStringForKey:kPrefkeyMqttHost];
	NSNumber *mqttPort = [dict helNumberForKey:kPrefkeyMqttPort];
	NSNumber *mqttSecureTransport = [dict helNumberForKey:kPrefkeyMqttSecureTransport];
	NSString *mqttUser = [dict helStringForKey:kPrefkeyMqttUser];
	NSString *uuid = [dict helStringForKey:kPrefkeyUuid];
	if (uuid.length > 0 && host.length > 0 && mqttHost.length > 0) {
		Account *account = [Account accountWithHost:host
										   mqttHost:mqttHost
										   mqttPort:mqttPort.intValue
								mqttSecureTransport:mqttSecureTransport.boolValue
										   mqttUser:mqttUser
											   uuid:uuid];
		account.pushServerID = [dict helStringForKey:kPrefkeyPushServerID];
		return account;
	} else {
		return nil;
	}
}

- (NSDictionary *)userDefaultsDict {
	// Required properties:
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 self.host, kPrefkeyHost,
								 self.mqttHost, kPrefkeyMqttHost,
								 @(self.mqttPort), kPrefkeyMqttPort,
								 @(self.mqttSecureTransport), kPrefkeyMqttSecureTransport,
								 self.mqttUser, kPrefkeyMqttUser,
								 self.uuid, kPrefkeyUuid,
								 nil];
	// Optional properties:
	dict[kPrefkeyPushServerID] = self.pushServerID;
	return dict;
}

- (BOOL) configure
{
	if (self.uuid.length == 0) {
		if (![self createUuidAndCacheURL])
			return NO;
	} else {
		if (![self createCacheURL])
			return NO;
	}
	
	if (![self setupCoreData])
		return NO;
	if (![self createCDAccount])
		return NO;

	return YES;
}

- (void)clearCache {
	NSPersistentStoreCoordinator *coord = self.cdcontainer.persistentStoreCoordinator;
	self.context = nil;
	self.backgroundContext = nil;
	self.cdaccount = nil;
	
	[coord performBlockAndWait:^{
		for (NSPersistentStore *store in coord.persistentStores) {
			NSError *error;
			if (![coord removePersistentStore:store error:&error]) {
				NSLog(@"%@", error);
			}
		}
	}];
	[[NSFileManager defaultManager] removeItemAtURL:self.cacheURL error:nil];
}

- (void)addMessageList:(NSArray<Message *>*)messageList updateSyncDate:(BOOL)updateSyncDate {
	NSManagedObjectContext *bgContext = self.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[bgContext
											 existingObjectWithID:self.cdaccount.objectID
											 error:NULL];
		[cdaccount addMessageList:messageList updateSyncDate:updateSyncDate];
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDictionary *userInfo = @{@"UpdatedServerKey" : self };
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ServerUpdateNotification" object:self userInfo:userInfo];
		});
	}];
}

- (void)deleteMessagesBefore:(NSDate *)before {
	NSManagedObjectContext *bgContext = self.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[bgContext
											 existingObjectWithID:self.cdaccount.objectID
											 error:NULL];
		[cdaccount deleteMessagesBefore:before];
	}];
}

- (void)restoreMessages {
	self.cdaccount.syncTimestamp = nil;
	self.cdaccount.syncMessageID = 0;
	[self.context save:NULL];
}

#pragma mark - Accessor methods

- (NSString *)mqttPassword {
	return [KeychainUtils passwordForAccount:self.uuid];
}

- (void)setMqttPassword:(NSString *)password {
	[KeychainUtils setPassword:password forAccount:self.uuid];
}

- (NSString *)mqttURI {
	return [NSString stringWithFormat:@"%@://%@:%d",
			self.mqttSecureTransport ? @"ssl" : @"tcp",
			self.mqttHost, self.mqttPort];
}

- (NSString *)accountID {
	if (self.mqttUser.length > 0) {
		return [NSString stringWithFormat:@"%@@%@:%d", self.mqttUser, self.mqttHost, self.mqttPort];
	} else {
		return [NSString stringWithFormat:@"@%@:%d", self.mqttHost, self.mqttPort];
	}
}

- (NSString *)accountDescription {
	if (self.mqttUser.length > 0) {
		return [NSString stringWithFormat:@"%@@%@:%d", self.mqttUser, self.mqttHost, self.mqttPort];
	} else {
		return [NSString stringWithFormat:@"%@:%d", self.mqttHost, self.mqttPort];
	}
}

#pragma mark - Local helper methods

static NSString *kCacheDirSuffix = @".mqttcache";

/*
 * This is called for new accounts.
 * Create a new, unique subdirectory `<uuid>.mqttcache` in the shared container,
 * and assign `uuid` and `cacheURL` properties.
 */
- (BOOL)createUuidAndCacheURL {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *cachesDirectory = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
	NSString *uuid = [NSString stringWithFormat:@"%08x", arc4random()];
	NSURL *cacheURL = [cachesDirectory
					   URLByAppendingPathComponent:[uuid stringByAppendingString:kCacheDirSuffix]
					   isDirectory:YES];
	
	int result;
	while ((result = mkdir(cacheURL.path.fileSystemRepresentation, 0777)) == -1 && errno == EEXIST) {
		uuid = [NSString stringWithFormat:@"%08x", arc4random()];
		cacheURL = [cachesDirectory
					URLByAppendingPathComponent:[uuid stringByAppendingString:kCacheDirSuffix]
					isDirectory:YES];
	}
	if (result != 0) {
		NSLog(@"Cannot create cache directory: %s", strerror(errno));
		return NO;
	}
	self.uuid = uuid;
	self.cacheURL = cacheURL;
	return YES;
}

/*
 * This is called for existing accounts.
 * Create `<uuid>.mqttcache` subdirectory in the shared container
 * if it does not already exists, and assign `cacheURL` property.
 */
- (BOOL)createCacheURL {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *cachesDirectory = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
	NSURL *cacheURL = [cachesDirectory
					   URLByAppendingPathComponent:[self.uuid stringByAppendingString:kCacheDirSuffix]
					   isDirectory:YES];
	if (mkdir(cacheURL.path.fileSystemRepresentation, 0777) == -1 && errno != EEXIST) {
		NSLog(@"Cannot create cache directory: %s", strerror(errno));
		return NO;
	}
	self.cacheURL = cacheURL;
	return YES;
}

- (BOOL)setupCoreData {
	
	// The managed object model must be loaded only once, otherwise
	//  "Multiple NSEntityDescriptions claim the NSManagedObject subclass ..."
	// errors can occur.
	static NSManagedObjectModel *model = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MQTT" withExtension:@"momd"];
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	});
	
	NSURL *storeURL = [self.cacheURL URLByAppendingPathComponent:@"messages.sqlite"];
	NSPersistentStoreDescription *desc = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:storeURL];
	desc.shouldInferMappingModelAutomatically = YES;
	desc.shouldMigrateStoreAutomatically = YES;
	desc.shouldAddStoreAsynchronously = NO;

	self.cdcontainer = [NSPersistentContainer persistentContainerWithName:@"MQTT" managedObjectModel:model];
	self.cdcontainer.persistentStoreDescriptions = @[desc];
	[self.cdcontainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *desc,
																  NSError *error) {
		if (error != nil) {
			NSLog(@"Cannot load %@: %@", desc.URL, error.localizedDescription);
		}
	}];
	
	if (self.cdcontainer.persistentStoreCoordinator.persistentStores.count == 0) {
		/*
		 * The most likely reason that the store could not be opened is that
		 * the Core Data model has been changed in the App and is now incompatible
		 * with the model that was used to create the store.
		 *
		 * The only thing we can do here is to delete the store and recreate it.
		 */
		[self clearCache];
		[[NSFileManager defaultManager] createDirectoryAtURL:self.cacheURL
								 withIntermediateDirectories:NO attributes:nil error:NULL];
		[self.cdcontainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *desc,
																	  NSError *error) {
			if (error != nil) {
				NSLog(@"Cannot load %@ (second attempt): %@", desc.URL, error.localizedDescription);
			}
		}];
		if (self.cdcontainer.persistentStoreCoordinator.persistentStores.count == 0) {
			return NO;
		}
	}

	// Main managed object context:
	self.context = self.cdcontainer.viewContext;
	self.context.undoManager = nil;
	
	// Create managed object context for background tasks:
	self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	self.backgroundContext.automaticallyMergesChangesFromParent = YES;
	self.backgroundContext.parentContext = self.context;
	self.backgroundContext.undoManager = nil;
	self.backgroundContext.mergePolicy = NSOverwriteMergePolicy;

	return YES;
}

- (BOOL) createCDAccount
{
	NSFetchRequest *fetchRequest = [CDAccount fetchRequest];
	
	NSError *error = nil;
	NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
	if (result == nil) {
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
		return NO;
	}
	if (result.count > 0) {
		self.cdaccount = result[0];
	} else {
		self.cdaccount = [NSEntityDescription insertNewObjectForEntityForName:@"CDAccount" inManagedObjectContext:self.context];
		[self.context save:&error];
	}
	return YES;
}

@end
