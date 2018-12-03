/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

#import "NotificationQueue.h"
#import "SharedConstants.h"

static NSString *kQueueDir = @"nq";	  // Subdirectory in shared container for notification messages.
static NSString *kFilePrefix = @"n."; // Prefix for each notification file.

@interface NotificationQueue ()

@property dispatch_source_t dirWatcher;
@property (weak) id<NotificationQueueDelegate> delegate;

@end

@implementation NotificationQueue

- (instancetype)init {
	self = [super init];
	if (self) {
		//_dirfd = -1;
	}
	return self;
}

- (void)dealloc {
	if (_dirWatcher != nil) {
		dispatch_source_cancel(_dirWatcher);
	}
}

- (BOOL)startWatchingWithDelegate:(id<NotificationQueueDelegate>)delegate {
	self.delegate = delegate;
	int dirfd = open([[self queueDirectory] fileSystemRepresentation], O_EVTONLY);
	if (dirfd == -1) {
		return NO;
	}
	self.dirWatcher = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, dirfd,
											 DISPATCH_VNODE_WRITE, dispatch_get_main_queue());
	if (self.dirWatcher == nil) {
		NSLog(@"Cannot create dispatch source");
		return NO;
	}
	dispatch_source_set_event_handler(self.dirWatcher,  ^{
		[self.delegate directoryDidChange:self];
	});
	dispatch_source_set_cancel_handler(self.dirWatcher,  ^{
		close(dirfd);
	});
	dispatch_resume(self.dirWatcher);
	return YES;
}

- (nullable NSURL *)queueDirectory {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSURL *container = [fm containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroup];
	NSURL *dir = [container URLByAppendingPathComponent:kQueueDir]; // Subdirectory for "notification queue"
	NSError *error = nil;
	if (![fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"Cannot create %@: %@", dir.path, error.localizedDescription);
		return nil;
	}
	return dir;
}

- (void)addNotification:(NSDictionary *)notification {
	NSURL *dir = [self queueDirectory];
	if (dir == nil) {
		return;
	}

	// Use milliseconds timestamp for unique file creation. 14 digits are enough until the year 5138.
	NSString *filename = [NSString stringWithFormat:@"%@%014d", kFilePrefix,
					  (int)([NSDate date].timeIntervalSince1970 * 1000)];
	NSURL *path = [dir URLByAppendingPathComponent:filename];
	
	NSError *error = nil;
	NSData *json = [NSJSONSerialization dataWithJSONObject:notification options:0 error:&error];
	if (json == nil) {
		NSLog(@"Cannot create JSON: %@", error.localizedDescription);
		return;
	}
	[json writeToURL:path atomically:YES];
}

- (nullable NSArray<NSDictionary *>*)notifications {
	NSURL *dir = [self queueDirectory];
	if (dir == nil) {
		return nil;
	}

	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray<NSURL *> *fileList = [fm contentsOfDirectoryAtURL:dir
								   includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLNameKey]
													  options:NSDirectoryEnumerationSkipsHiddenFiles
														error:&error];
	if (fileList == nil) {
		NSLog(@"Cannot create %@: %@", dir.path, error.localizedDescription);
		return nil;
	}
	if (fileList.count == 0) {
		return @[];
	}

	NSMutableArray *notificationList = [NSMutableArray arrayWithCapacity:fileList.count];
	for (NSURL *url in fileList) {
		if (url.isFileURL && [url.lastPathComponent hasPrefix:kFilePrefix]) {
			NSData *data = [NSData dataWithContentsOfURL:url];
			[fm removeItemAtURL:url error:NULL];
			if (data != nil) {
				NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
				if (userInfo != nil) {
					[notificationList addObject:userInfo];
				}
			}
		}
	}
	
	return notificationList;
}

@end
