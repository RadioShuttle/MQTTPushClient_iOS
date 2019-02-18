/*
 * $Id$
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Security;
#include <stdatomic.h>
#include "Trace.h"
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

+ (NSData *)deviceId
{
	static const char *kKeychainItemIdentifier = "de.helios.MQTTPushClient.deviceId";
	static NSData *theUUID = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		/*
		 * Check if the UUID is already stored in the Keychain ...
		 */
		NSData *identifier = [NSData dataWithBytes:kKeychainItemIdentifier length:strlen(kKeychainItemIdentifier)];
		NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
								(__bridge id)kSecAttrGeneric: identifier,
								(__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
								(__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue};
		CFTypeRef cfresult;
		if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &cfresult) == noErr) {
			/*
			 * ... yes. Use value from Keychain.
			 */
			theUUID = (__bridge_transfer NSData *)cfresult;
			TRACE(@"old deviceId: %@", theUUID);
		} else {
			/*
			 * ... no. Create a unique ID and store it in the Keychain.
			 */
			uint8_t randomBytes[16] = {};
			while (SecRandomCopyBytes(kSecRandomDefault, sizeof(randomBytes), randomBytes) != errSecSuccess) {
				[NSThread sleepForTimeInterval:0.1];
			}
			theUUID = [NSData dataWithBytes:randomBytes length:sizeof(randomBytes)];
			NSDictionary *attr = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
								   (__bridge id)kSecAttrGeneric: identifier,
								   (__bridge id)kSecValueData: theUUID};
			SecItemAdd((__bridge CFDictionaryRef)attr, NULL);
			TRACE(@"new deviceId: %@", theUUID);
		}
	});
	
	return theUUID;
}

@end
