/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "TokenManager.h"
#import "FIRMessaging.h"
#import "Trace.h"

/*
 * Key for a string list user default, containing the FCM sender IDs for
 * tokens which haven't yet been deleted due to network problems.
 */
static NSString *kPrefkeyPendingDeleteIDs = @"PendingDeleteIDs";

@interface TokenManager ()
@property dispatch_source_t timer;
@end

@implementation TokenManager

+ (instancetype)sharedTokenManager {
	static TokenManager *_sharedTokenManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedTokenManager = [[TokenManager alloc] init];
	});
	return _sharedTokenManager;
}

- (void)deleteTokenFor:(NSString *)senderID {
	if (senderID.length == 0) {
		return;
	}
	TRACE(@"deleteFCMTokenForSenderID: %@", senderID);
	[[FIRMessaging messaging] deleteFCMTokenForSenderID:senderID completion:^(NSError *error) {
		TRACE(@"deleteFCMTokenForSenderID: %@, error=%@", senderID, error);
		if (error != nil && [error.domain isEqualToString:NSURLErrorDomain]) {
			/*
			 * Failed because of network problems. Add to pending list, so that
			 * another attempt is made later.
			 */
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSMutableArray *pending = [[defaults stringArrayForKey:kPrefkeyPendingDeleteIDs] mutableCopy];
			if (pending == nil) {
				pending = [NSMutableArray array];
			}
			[pending addObject:senderID];
			[defaults setObject:pending forKey:kPrefkeyPendingDeleteIDs];
		}
	}];
}

/*
 * Start a timer which regularly retries to delete outdated FCM tokens.
 */
- (void)resume {
#ifdef DEBUG
	uint64_t interval = 10 * NSEC_PER_SEC; // 10 seconds
#else
	uint64_t interval = 60 * NSEC_PER_SEC; // 1 minute
#endif
	self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
	dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, interval, interval);
	dispatch_source_set_event_handler(self.timer, ^{
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSArray *pending = [defaults stringArrayForKey:kPrefkeyPendingDeleteIDs];
		[defaults removeObjectForKey:kPrefkeyPendingDeleteIDs];
		TRACE(@"%ld pending entries", pending.count);

		for (NSString *senderID in pending) {
			[self deleteTokenFor:senderID];
		}
	});
	dispatch_resume(self.timer);
}

@end
