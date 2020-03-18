/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "AccountList.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "SharedConstants.h"

@interface AccountList ()
@property NSMutableArray<Account *> *accounts;
@end

@implementation AccountList

+ (nullable Account *)loadAccount:(NSString *)pushServerID accountID:(NSString *)accountID {
	NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroup];
	NSArray *accountsPref = [sharedDefaults arrayForKey:@"Accounts"];
	if (accountsPref != nil) {
		for (NSDictionary *dict in accountsPref) {
			Account *account = [Account accountFromUserDefaultsDict:dict];
			if (account != nil && [account.pushServerID isEqualToString:pushServerID]
				&& [account.accountID isEqualToString:accountID]) {
				return account;
			}
		}
	}
	return nil;
}

#ifndef MQTT_EXTENSION

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
		for (NSDictionary *dict in accountsPref) {
			Account *account = [Account accountFromUserDefaultsDict:dict];
			if (account != nil) {
				if ([self accountWithUuid:account.uuid] == nil) {
					if ([account configure]) {
						[self addAccount:account];
					}
				} else {
					NSLog(@"Duplicate account uuid '%@' in preferences", account.uuid);
				}
			}
		}
	}
}

- (void)save {
	NSMutableArray *accountsPref = [NSMutableArray arrayWithCapacity:self.accounts.count];
	for (Account *account in self.accounts) {
		NSDictionary *dict = [account userDefaultsDict];
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

#endif

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state
								  objects:(id  _Nullable __unsafe_unretained * _Nonnull)buffer
									count:(NSUInteger)len {
	
	return [self.accounts countByEnumeratingWithState:state
											  objects:buffer
												count:len];
}

@end
