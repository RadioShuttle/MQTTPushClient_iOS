/*
 * Copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
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
