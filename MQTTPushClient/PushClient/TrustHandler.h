/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;
@import Security;

NS_ASSUME_NONNULL_BEGIN

@interface TrustHandler : NSObject

+ (instancetype)shared;
- (void)evaluateTrust:(SecTrustRef)trust
			  forHost:(NSString *) host
	completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler;

@end

NS_ASSUME_NONNULL_END
