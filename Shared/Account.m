/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "KeychainUtils.h"
#import "SharedConstants.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "Message.h"
#include <sys/stat.h>    // for mkdir()

static NSString *kPrefkeyHost = @"pushserver.host";
static NSString *kPrefkeyMqttHost = @"mqtt.host";
static NSString *kPrefkeyMqttSecureTransport = @"mqtt.securetransport";
static NSString *kPrefkeyMqttUser = @"mqtt.user";
static NSString *kPrefkeyUuid = @"uuid";
static NSString *kPrefkeyPushServerID = @"pushserver.id";

@interface Account ()

// Public read-only property are internally read-write:
@property(readwrite, copy) NSString *host;
@property(readwrite, copy) NSString *mqttHost;
@property(readwrite) BOOL mqttSecureTransport;
@property(readwrite, copy) NSString *mqttUser;
@property(readwrite, copy) NSString *uuid;
@property(readwrite, copy) NSURL *cacheURL;
@property(readwrite) NSManagedObjectContext *context;
@property(readwrite) NSManagedObjectContext *backgroundContext;
@property(readwrite) CDAccount *cdaccount;

@end

@implementation Account

+ (instancetype)accountWithHost:(NSString *)host
					   mqttHost:(NSString *)mqttHost
			mqttSecureTransport:(BOOL)mqttSecureTransport
					   mqttUser:(NSString *)mqttUser
						   uuid:(nullable NSString *)uuid {
	
	Account *account = [[Account alloc] init];
	account.host = host;
	account.mqttHost = mqttHost;
	account.mqttSecureTransport = mqttSecureTransport;
	account.mqttUser = mqttUser;
	account.uuid = uuid;
	
	account.topicList = [NSMutableArray array];
	account.actionList = [NSMutableArray array];
	return account;
}

+ (nullable instancetype)accountFromUserDefaultsDict:(NSDictionary *)dict {
	NSString *host = [dict helStringForKey:kPrefkeyHost];
	NSString *mqttHost = [dict helStringForKey:kPrefkeyMqttHost];
	NSNumber *mqttSecureTransport = [dict helNumberForKey:kPrefkeyMqttSecureTransport];
	NSString *mqttUser = [dict helStringForKey:kPrefkeyMqttUser];
	NSString *uuid = [dict helStringForKey:kPrefkeyUuid];
	if (uuid.length > 0 && host.length > 0 && mqttHost.length > 0 && mqttUser.length > 0) {
		Account *account = [Account accountWithHost:host
										   mqttHost:mqttHost
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(backgroundContextDidSave:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:self.backgroundContext];
	
	
	return YES;
}

- (void)clearCache {
	NSPersistentStoreCoordinator *coord = self.context.persistentStoreCoordinator;
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

- (void)addMessageList:(NSArray<Message *>*)messageList {
	NSManagedObjectContext *bgContext = self.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[self.backgroundContext
											 existingObjectWithID:self.cdaccount.objectID
											 error:NULL];
		[cdaccount addMessageList:messageList];
	}];
}

- (void)deleteMessagesBefore:(NSDate *)before {
	NSManagedObjectContext *bgContext = self.backgroundContext;
	[bgContext performBlock:^{
		CDAccount *cdaccount = (CDAccount *)[self.backgroundContext
											 existingObjectWithID:self.cdaccount.objectID
											 error:NULL];
		[cdaccount deleteMessagesBefore:before];
	}];
}

- (void)restoreMessages {
	self.cdaccount.lastTimestamp = nil;
	self.cdaccount.lastMessageID = 0;
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
	NSMutableString *uri = [NSMutableString string];
	[uri appendString:self.mqttSecureTransport ? @"ssl://" : @"tcp://"];
	NSRange range = [self.mqttHost rangeOfString:@":" options:NSBackwardsSearch];
	if (range.location == NSNotFound) {
		[uri appendFormat:@"%@:%d", self.mqttHost, MQTT_DEFAULT_PORT];
	} else {
		[uri appendString:self.mqttHost];
	}
	return uri;
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
	NSURL *container = [fm containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroup];
	NSString *uuid = [NSString stringWithFormat:@"%08x", arc4random()];
	NSURL *cacheURL = [container
					   URLByAppendingPathComponent:[uuid stringByAppendingString:kCacheDirSuffix]
					   isDirectory:YES];
	
	int result;
	while ((result = mkdir(cacheURL.path.fileSystemRepresentation, 0777)) == -1 && errno == EEXIST) {
		uuid = [NSString stringWithFormat:@"%08x", arc4random()];
		cacheURL = [container
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
	NSURL *container = [fm containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroup];
	NSURL *cacheURL = [container
					   URLByAppendingPathComponent:[self.uuid stringByAppendingString:kCacheDirSuffix]
					   isDirectory:YES];
	if (mkdir(cacheURL.path.fileSystemRepresentation, 0777) == -1 && errno != EEXIST) {
		NSLog(@"Cannot create cache directory: %s", strerror(errno));
		return NO;
	}
	self.cacheURL = cacheURL;
	return YES;
}

- (BOOL) setupCoreData
{
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MQTT" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	// Create persistent store:
	NSError *error;
	NSURL *storeURL = [self.cacheURL URLByAppendingPathComponent:@"messages.sqlite"];
	NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	// Automatic migration from previous version, using the given mapping model:
	NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
							  NSInferMappingModelAutomaticallyOption: @NO};
	
	NSPersistentStore *store = [coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
	if (store == nil) {
		NSLog(@"Could not open store (first attempt). URL=%@, error=%@", storeURL, error.userInfo);
		/*
		 * The most likely reason that the store could not be opened is that
		 * the Core Data model has been changed in the App and is now incompatible
		 * with the model that was used to create the store.
		 *
		 * The only thing we can do here is to delete the store and recreate it.
		 * We delete the entire cache directory, because all downloaded files
		 * are not accessible anymore if the store is recreated.
		 */
		[self clearCache];
		[[NSFileManager defaultManager] createDirectoryAtURL:self.cacheURL withIntermediateDirectories:NO attributes:nil error:NULL];
		store = [coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
		if (store == nil) {
			NSLog(@"Could not open store (second attempt). URL=%@, error=%@", storeURL, error.userInfo);
			return NO;
		}
	}
	
	// Create main managed object context:
	self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	self.context.persistentStoreCoordinator = coord;
	self.context.undoManager = nil;
	
	// Create managed object context for background tasks:
	self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	self.backgroundContext.persistentStoreCoordinator = coord;
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

- (void)backgroundContextDidSave:(NSNotification *)notification
{
	[self.context performBlock:^{
		[self.context mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
