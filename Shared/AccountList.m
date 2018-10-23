/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "AccountList.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "SharedConstants.h"

static NSString *kPrefkeyHost = @"pushserver.host";
static NSString *kPrefkeyMqttHost = @"mqtt.host";
static NSString *kPrefkeyMqttSecureTransport = @"mqtt.securetransport";
static NSString *kPrefkeyMqttUser = @"mqtt.user";
static NSString *kPrefkeyUuid = @"uuid";
static NSString *kPrefkeyPushServerID = @"pushserver.id";

@interface AccountList ()
@property NSMutableArray<Account *> *accounts;
@end

@implementation AccountList

// Private
- (instancetype)init {
	if ((self = [super init]) != nil) {
		_accounts = [NSMutableArray array];
	}
	return self;
}

+ (instancetype)sharedAccountList {
	static AccountList *_sharedAccountList;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedAccountList = [[AccountList alloc] init];
		[_sharedAccountList load];
	});
	return _sharedAccountList;
}

- (NSUInteger)count {
	return self.accounts.count;
}

- (Account *)objectAtIndexedSubscript:(NSUInteger)index {
	return self.accounts[index];
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state
								  objects:(id  _Nullable __unsafe_unretained * _Nonnull)buffer
									count:(NSUInteger)len {

	return [self.accounts countByEnumeratingWithState:state
											  objects:buffer
												count:len];
}

- (void)addAccount:(Account *)account {
	[self.accounts addObject:account];
}

- (void)removeAccountAtIndex:(NSUInteger) index {
	Account *account = self.accounts[index];
	account.mqttPassword = nil; // Remove password from Keychain
	[self.accounts removeObjectAtIndex:index];
}

- (void)moveAccountAtIndex:(NSUInteger) fromIndex toIndex:(NSUInteger) toIndex {
	Account *account = self.accounts[fromIndex];
	[self.accounts removeObjectAtIndex:fromIndex];
	[self.accounts insertObject:account atIndex:toIndex];
}

// Private
- (void)load {
	[self.accounts removeAllObjects];
	NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroup];
	NSArray *accountsPref = [sharedDefaults arrayForKey:@"Accounts"];
	if (accountsPref != nil) {
		for (NSDictionary *d in accountsPref) {
			NSString *host = [d helStringForKey:kPrefkeyHost];
			NSString *mqttHost = [d helStringForKey:kPrefkeyMqttHost];
			NSNumber *mqttSecureTransport = [d helNumberForKey:kPrefkeyMqttSecureTransport];
			NSString *mqttUser = [d helStringForKey:kPrefkeyMqttUser];
			NSString *uuid = [d helStringForKey:kPrefkeyUuid];
			if (uuid.length > 0 && host.length > 0 && mqttHost.length > 0 && mqttUser.length > 0) {
				if ([self accountWithUuid:uuid] == nil) {
					Account *account = [Account accountWithHost:host
															 mqttHost:mqttHost
												  mqttSecureTransport:mqttSecureTransport.boolValue
															 mqttUser:mqttUser
																 uuid:uuid];
					if ([account configure]) {
						[self addAccount:account];
						account.pushServerID = [d helStringForKey:kPrefkeyPushServerID];
					}
				} else {
					NSLog(@"Duplicate account uuid '%@' in preferences", uuid);
				}
			}
		}
	}
}

- (void)save {
	NSMutableArray *accountsPref = [NSMutableArray arrayWithCapacity:self.accounts.count];
	for (Account *account in self.accounts) {
		// Required properties:
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  account.host, kPrefkeyHost,
								  account.mqttHost, kPrefkeyMqttHost,
								  @(account.mqttSecureTransport), kPrefkeyMqttSecureTransport,
								  account.mqttUser, kPrefkeyMqttUser,
								  account.uuid, kPrefkeyUuid,
								  nil];
		// Optional properties:
		dict[kPrefkeyPushServerID] = account.pushServerID;
		[accountsPref addObject:dict];
	}
	NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroup];
	[sharedDefaults setObject:accountsPref forKey:@"Accounts"];
	[sharedDefaults synchronize];
}

#pragma mark - Local helper methods

- (Account *)accountWithUuid: (NSString *)uuid {
	for (Account *account in self.accounts) {
		if ([account.uuid isEqualToString:uuid]) {
			return account;
		}
	}
	return nil;
}

@end
