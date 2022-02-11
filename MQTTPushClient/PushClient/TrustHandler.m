/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

@import UIKit;
#import "TrustHandler.h"
#import "UIAlertController+Window.h"
#import "NSDictionary+HelSafeAccessors.h"

// User defaults keys for storing the certificate exceptions.
static NSString *kPrefkeyTrustExceptions = @"TrustExceptions";
static NSString *kPrefkeySerial = @"SerialNumber";
static NSString *kPrefkeyData = @"ExceptionData";
static NSString *kPrefkeyExpires = @"ExpireDate";

@interface CertException : NSObject
@property(copy) NSData *exception;
@property NSDate *expires;
@end

@implementation CertException
@end

#pragma mark -

@interface TrustHandler ()

// Mapping from certificate serial number to certifcate exception.
@property NSMutableDictionary<NSString *, CertException *> *certExceptions;

@end

@implementation TrustHandler

+ (instancetype) shared {
	static TrustHandler *_sharedExceptionList;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedExceptionList = [[self alloc] init];
		[_sharedExceptionList loadExceptionsList];
	});
	return _sharedExceptionList;
}

- (instancetype) init {
	self = [super init];
	if (self) {
		_certExceptions = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)loadExceptionsList {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *array = [defaults arrayForKey:kPrefkeyTrustExceptions];
	if (array != nil) {
		for (NSDictionary *dict in array) {
			if ([dict isKindOfClass:[NSDictionary class]]) {
				NSString *serial = [dict helStringForKey:kPrefkeySerial];
				NSData *exception = [dict helDataForKey:kPrefkeyData];
				NSDate *expires = [dict helDateForKey:kPrefkeyExpires];
				if (serial != nil && exception != nil && expires != nil
					&& [expires timeIntervalSinceNow] > 0) {
					CertException *ce = [[CertException alloc] init];
					ce.exception = exception;
					ce.expires = expires;
					self.certExceptions[serial] = ce;
				}
			}
		}
	}
}

- (void)saveExceptionList {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.certExceptions.count];
	[self.certExceptions enumerateKeysAndObjectsUsingBlock:^(NSString *serial, CertException *ce, BOOL *stop) {
		NSDictionary *dict = @{
							   kPrefkeySerial: serial,
							   kPrefkeyData: ce.exception,
							   kPrefkeyExpires: ce.expires
							   };
		[array addObject:dict];
	}];
	[defaults setObject:array forKey:kPrefkeyTrustExceptions];
}

// Get serial number from certificate (as Base64 encoded string).
- (nullable NSString *)certSerialNumber:(SecCertificateRef)cert {
	if (cert == NULL) {
		return nil;
	}
	CFDataRef ser = SecCertificateCopySerialNumber(cert);
	if (ser == NULL) {
		return nil;
	}
	NSData *data = (__bridge_transfer NSData *)ser;
	return [data base64EncodedStringWithOptions:0];
}

// User has decided to trust this certificate. Store exception in dictionary
// and save to user defaults.
- (void)saveCertExceptions:(SecTrustRef)trust forSerialNumber:(nullable NSString *)certSerial {
	if (certSerial == nil) {
		return;
	}
	CFDataRef exceptions = SecTrustCopyExceptions(trust);
	if (exceptions != NULL) {
		CertException *ce = [[CertException alloc] init];
		ce.exception = (__bridge_transfer NSData *)exceptions;
		ce.expires = [NSDate dateWithTimeIntervalSinceNow:24 * 3600];
		self.certExceptions[certSerial] = ce;
		[self saveExceptionList];
	}
}

// Check if we have an exception for this certificate, which is not yet expired, and
// can be added to the trust.
- (BOOL)addCertExceptions:(SecTrustRef)trust forSerialNumber:(nullable NSString *)certSerial {
	if (certSerial == nil) {
		return NO;
	}
	CertException *ce = self.certExceptions[certSerial];
	if (ce == nil) {
		return NO;
	}
	if ([ce.expires timeIntervalSinceNow] < 0) {
		// Expired
		return NO;
	}
	BOOL success = SecTrustSetExceptions(trust, (__bridge CFDataRef) ce.exception);
	return success;
}

- (void)removeCertExceptionsFor:(nullable NSString *)certSerial {
	if (certSerial == nil) {
		return;
	}
	[self.certExceptions removeObjectForKey:certSerial];
	[self saveExceptionList];
}

- (BOOL)evaluateTrust:(SecTrustRef)trust {
	SecTrustResultType result = kSecTrustResultDeny;
	OSStatus status = SecTrustEvaluate(trust, &result);
	BOOL trusted = (status == noErr) && ((result == kSecTrustResultProceed || result == kSecTrustResultUnspecified));
	return trusted;
}

- (void)evaluateTrust:(SecTrustRef)trust
			  forHost:(NSString *) host
	completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
	
	// Load "ca-certificate.der":
	static CFArrayRef trustedAnchors = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *certUrl = [[NSBundle mainBundle] URLForResource:@"ca-certificate" withExtension:@"der"];
		NSData *certData = [NSData dataWithContentsOfURL:certUrl];
		SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certData);
		if (cert != NULL) {
			trustedAnchors = CFArrayCreate(NULL, (void *)&cert, 1, &kCFTypeArrayCallBacks);
			CFRelease(cert);
		}
	});

	if (trustedAnchors != NULL) {
		SecTrustSetAnchorCertificates(trust, trustedAnchors);
		SecTrustSetAnchorCertificatesOnly(trust, false);
		
		/* ssl with host verification: */
		// SecPolicyRef policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)host);

		/* use BasicX509 policy which does not have any restrictions regading period of validity. */
		SecPolicyRef policy = SecPolicyCreateBasicX509();
		SecTrustSetPolicies(trust, policy);
		// CFShow(policy);
		CFRelease(policy);
	}

	SecCertificateRef cert = SecTrustGetCertificateCount(trust) ? SecTrustGetCertificateAtIndex(trust, 0) : NULL;
	NSString *serial = [self certSerialNumber:cert];
	
	// First attempt to verify the trust:
	if ([self evaluateTrust:trust]) {
		[self removeCertExceptionsFor:serial];
		completionHandler(YES);
		return;
	}

	// Add exceptions and try again:
	if ([self addCertExceptions:trust forSerialNumber:serial]) {
		if ([self evaluateTrust:trust]) {
			completionHandler(YES);
			return;
		}
	}
	[self removeCertExceptionsFor:serial];

	// Ask user:
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSString *title = @"Security Warning";
		NSString *msg = [NSString stringWithFormat:@"Push Server “%@” uses an invalid certificate.\n\n"
						 "Would you like to continue anyway?",
						 host];
		
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
																	   message:msg
																preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue"
																 style:UIAlertActionStyleDestructive
															   handler:^(UIAlertAction *action) {
			[self saveCertExceptions:trust forSerialNumber:serial];
			completionHandler(YES);
		}];
		[alert addAction:continueAction];
		// "Cancel" is the recommended action, therefore is should be the right (second) button.
		UIAlertAction *cancelAction = [ UIAlertAction actionWithTitle:@"Cancel"
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction *action) {
			completionHandler(NO);
		}];
		[alert addAction:cancelAction];
		[alert helShow];
	});
}

@end
