/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "Account.h"
#import "KeychainUtils.h"
#import "SharedConstants.h"
#include <sys/stat.h>    // for mkdir()

@interface Account ()

// Public read-only property are internally read-write:
@property(readwrite, copy) NSString *host;
@property(readwrite, copy) NSString *mqttHost;
@property(readwrite) BOOL mqttSecureTransport;
@property(readwrite, copy) NSString *mqttUser;
@property(readwrite, copy) NSString *uuid;
@property(readwrite, copy) NSURL *cacheURL;

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
	
	account.messageList = [NSMutableArray array];
	account.topicList = [NSMutableArray array];
	return account;
}

- (BOOL)configure {
	if (self.uuid == nil) {
		return [self createUuidAndCacheURL];
	} else {
		return [self createCacheURL];
	}
}

- (void)clearCache {
	[[NSFileManager defaultManager] removeItemAtURL:self.cacheURL error:nil];
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

@end
