/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import Security;
#include <stdatomic.h>

#import "KeychainUtils.h"

@implementation KeychainUtils

+ (void)setPassword:(NSString *)password forAccount:(NSString *)accountUuid
{
	if (password == nil) {
		/*
		 * Delete password.
		 */
		NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
		query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;
		query[(__bridge id)kSecAttrServer] = accountUuid;
		SecItemDelete((__bridge CFDictionaryRef)query);
	} else {
		/*
		 * Set or update password.
		 */
		NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
		query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;
		query[(__bridge id)kSecAttrServer] = accountUuid;
		NSData *pwdata = [password dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
		attr[(__bridge id)kSecValueData] = pwdata;
		if (SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attr) == errSecItemNotFound) {
			[attr addEntriesFromDictionary:query];
			SecItemAdd((__bridge CFDictionaryRef)attr, NULL);
		}
	}
}

+ (NSString *)passwordForAccount:(NSString *)accountUuid
{
	NSString *thePassword = nil;
	NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
	query[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;
	query[(__bridge id)kSecAttrServer] = accountUuid;
	query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
	query[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
	CFTypeRef cfresult;
	if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &cfresult) == noErr) {
		NSData *pwdata = (__bridge_transfer NSData *)cfresult;
		thePassword = [[NSString alloc] initWithData:pwdata encoding:NSUTF8StringEncoding];
	}
	return thePassword;
}

@end
