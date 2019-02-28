/*
 * $Id$
 * This is an unpublished work copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "TokenManager.h"
#import "FIRMessaging.h"
#import "Trace.h"

static NSString *kPrefkeyPendingDeleteIDs = @"PendingDeleteIDs";

@interface TokenManager ()

@property NSMutableArray<NSString *> *pendingDeleteIds;
@property dispatch_source_t timer;
@end

@implementation TokenManager

// Private
- (instancetype)init {
	if ((self = [super init]) != nil) {
		_pendingDeleteIds = [NSMutableArray array];
	}
	return self;
}

+ (instancetype)sharedTokenManager {
	static TokenManager *_sharedTokenManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedTokenManager = [[TokenManager alloc] init];
		[_sharedTokenManager load];
	});
	return _sharedTokenManager;
}

- (void)load {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *pending = [defaults stringArrayForKey:kPrefkeyPendingDeleteIDs];
	if (pending != nil) {
		[self.pendingDeleteIds addObjectsFromArray:pending];
	}
}

- (void)save {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:self.pendingDeleteIds forKey:kPrefkeyPendingDeleteIDs];

}

- (void)deleteTokenFor:(NSString *)senderID {
	if (senderID.length == 0) {
		return;
	}
	TRACE(@"deleteFCMTokenForSenderID: %@", senderID);
	[[FIRMessaging messaging] deleteFCMTokenForSenderID:senderID completion:^(NSError *error) {
		TRACE(@"deleteFCMTokenForSenderID: %@, error=%@", senderID, error);
		if ([error.domain isEqualToString:NSURLErrorDomain]) {
			[self.pendingDeleteIds addObject:senderID];
			[self save];
		}
	}];
}

- (void)resume {
	self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
	dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC, 10 * NSEC_PER_SEC);
	dispatch_source_set_event_handler(self.timer, ^{
		NSArray *pending = self.pendingDeleteIds;
		self.pendingDeleteIds = [NSMutableArray array];
		for (NSString *senderID in pending) {
			[self deleteTokenFor:senderID];
		}
	});
	dispatch_resume(self.timer);
}

@end
