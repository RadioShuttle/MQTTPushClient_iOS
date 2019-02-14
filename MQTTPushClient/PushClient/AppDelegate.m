/*
 * $Id$
 * This is an unpublished work copyright (c) 2018 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Firebase;
@import UserNotifications;
#import "Account.h"
#import "Connection.h"
#import "MessageDataHandler.h"
#import "AppDelegate.h"
#import "AccountList.h"
#import "NotificationQueue.h"
#include "Trace.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate, NotificationQueueDelegate>

@property(nullable) NSData *deviceToken;
@property NotificationQueue *notificationQueue;

@end

@implementation AppDelegate

NSString *const kGCMMessageIDKey = @"gcm.message_id";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.fcmToken = nil;
	self.deviceToken = nil;
	
	[UNUserNotificationCenter currentNotificationCenter].delegate = self;
	UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
	[[UNUserNotificationCenter currentNotificationCenter]
	 requestAuthorizationWithOptions:authOptions
	 completionHandler:^(BOOL granted, NSError * _Nullable error) {
		 // ...
	 }];
	[application registerForRemoteNotifications];
	
	self.notificationQueue = [NotificationQueue new];
	[self.notificationQueue startWatchingWithDelegate:self];

	return YES;
}

- (void)startMessaging {
	[FIRMessaging messaging].delegate = self;
	[FIRMessaging messaging].APNSToken = self.deviceToken;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	[[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
	
	[self directoryDidChange:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Firebase Cloud Messaging
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	// With swizzling disabled you must let Messaging know about the message, for Analytics
	[[FIRMessaging messaging] appDidReceiveMessage:userInfo];
	
	TRACE(@"didReceiveRemoteNotification: message ID=%@", userInfo[kGCMMessageIDKey]);

	NSString *pushServerID = userInfo[@"pushserverid"];
	NSString *accountID = userInfo[@"account"];
	
	for (Account *account in [AccountList sharedAccountList]) {
		if ([pushServerID isEqualToString:account.pushServerID]
			&& [accountID isEqualToString:account.accountID]) {
			NSInteger maxPrio = 0;
			NSArray<Message *>*messageList = [MessageDataHandler messageListFromRemoteMessage:userInfo
																				   maxPrioPtr:&maxPrio];
			[account addMessageList:messageList updateSyncDate:NO];
			if (maxPrio >= 2) {
				application.applicationIconBadgeNumber = 1;
			}
			break;
		}
	}

	completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Unable to register for remote notifications: %@", error);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	TRACE(@"APNs device token retrieved: %@", deviceToken);
	self.deviceToken = deviceToken;
	for (Account *account in [AccountList sharedAccountList]) {
		Connection *connection = [[Connection alloc] init];
		[connection getFcmDataForAccount:account];
	}
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
	TRACE(@"FCM registration token: %@", fcmToken);
	self.fcmToken = fcmToken;
}

#pragma mark - NotificationQueueDelegate

- (void)directoryDidChange:(NotificationQueue *)notificationQueue {
	NSArray *notifications = [self.notificationQueue notifications];
	// TRACE(@"%@: %d queued notifications", notificationQueue, (int)notifications.count);
	for (NSDictionary *notification in notifications) {
		NSString *pushServerID = notification[@"pushserverid"];
		NSString *accountID = notification[@"account"];
		
		for (Account *account in [AccountList sharedAccountList]) {
			if ([pushServerID isEqualToString:account.pushServerID]
				&& [accountID isEqualToString:account.accountID]) {
				NSArray<Message *>*messageList = [MessageDataHandler messageListFromRemoteMessage:notification maxPrioPtr:NULL];
				[account addMessageList:messageList updateSyncDate:NO];
				break;
			}
		}
	}
}

@end
