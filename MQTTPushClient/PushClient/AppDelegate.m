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

@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>

@end

@implementation AppDelegate

NSString *const kGCMMessageIDKey = @"gcm.message_id";

- (void)openAccounts {
	self.accountList = [[NSMutableArray alloc] init];
	NSError *error;
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
	if (url) {
		url = [url URLByAppendingPathComponent:@"ServerList.xml"];
		NSData *data = [NSData dataWithContentsOfURL:url];
		if (data) {
			NSArray *properties = (NSArray *)[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error];
			self.accountList = [NSMutableArray arrayWithCapacity:properties.count];
			for (NSDictionary *dictionary in properties) {
				Account *account = [[Account alloc] init];
				account.host = [dictionary objectForKey:@"address"];
				account.mqtt.host = [dictionary objectForKey:@"mqtt.address"];
				account.mqtt.port = [dictionary objectForKey:@"mqtt.port"];
				NSNumber *secureTransport = [dictionary objectForKey:@"mqtt.secureTransport"];
				account.mqtt.user = [dictionary objectForKey:@"mqtt.user"];
				account.mqtt.password = [dictionary objectForKey:@"mqtt.password"];
				if (!account.host)
					account.host = @"";
				if (!account.mqtt.host)
					account.mqtt.host = @"";
				if (!account.mqtt.port)
					account.mqtt.port = [NSNumber numberWithInt:MQTT_DEFAULT_PORT];
				if (secureTransport)
					account.mqtt.secureTransport = secureTransport.boolValue;
				else
					account.mqtt.secureTransport = NO;
				if (!account.mqtt.user)
					account.mqtt.user = @"";
				if (!account.mqtt.password)
					account.mqtt.password = @"";
				[self.accountList addObject:account];
			}
		}
	}
}

- (void)saveAccounts {
	NSError *error;
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
	if (url) {
		url = [url URLByAppendingPathComponent:@"ServerList.xml"];
		NSMutableArray *servers = [NSMutableArray arrayWithCapacity:[self.accountList count]];
		for (Account *account in self.accountList) {
			NSNumber *secureTransport = [NSNumber numberWithBool:account.mqtt.secureTransport];
			NSDictionary *dictionary = @{@"address": account.host, @"mqtt.address": account.mqtt.host, @"mqtt.port": account.mqtt.port, @"mqtt.secureTransport": secureTransport, @"mqtt.user": account.mqtt.user, @"mqtt.password": account.mqtt.password};
			[servers addObject:dictionary];
		}
		NSData *data = [NSPropertyListSerialization dataWithPropertyList:servers format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
		[data writeToURL:url atomically:YES];
	}
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self openAccounts];
	self.fcmToken = nil;
	[FIRApp configure];
	[[FIRAnalyticsConfiguration sharedInstance] setAnalyticsCollectionEnabled:NO];
	[FIRMessaging messaging].shouldEstablishDirectChannel = YES;
	[FIRMessaging messaging].delegate = self;
	if ([UNUserNotificationCenter class] != nil) {
		// iOS 10 or later
		// For iOS 10 display notification (sent via APNS)
		[UNUserNotificationCenter currentNotificationCenter].delegate = self;
		UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
		UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
		[[UNUserNotificationCenter currentNotificationCenter]
		 requestAuthorizationWithOptions:authOptions
		 completionHandler:^(BOOL granted, NSError * _Nullable error) {
			 // ...
		 }];
	}
	[application registerForRemoteNotifications];
	for (Account *account in self.accountList) {
		Connection *connection = [[Connection alloc] init];
		[connection getFcmDataForAccount:account];
	}
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

















// Firebase Cloud Messaging
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	// If you are receiving a notification message while your app is in the background,
	// this callback will not be fired till the user taps on the notification launching the application.
	// TODO: Handle data of notification
	
	// With swizzling disabled you must let Messaging know about the message, for Analytics
	// [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
	
	// Print full message.
	NSLog(@"didReceiveRemoteNotification: %@", userInfo);
	
	completionHandler(UIBackgroundFetchResultNewData);

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Unable to register for remote notifications: %@", error);

}

// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs device token can be paired to
// the FCM registration token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"APNs device token retrieved: %@", deviceToken);
	
	// With swizzling disabled you must set the APNs device token here.
	// [FIRMessaging messaging].APNSToken = deviceToken;
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
	NSLog(@"FCM registration token: %@", fcmToken);
	
	// TODO: If necessary send token to application server.
	// Note: This callback is fired at each app startup and whenever a new token is generated.
	self.fcmToken = fcmToken;
}

// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
	   willPresentNotification:(UNNotification *)notification
		 withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	NSDictionary *userInfo = notification.request.content.userInfo;
	
	// With swizzling disabled you must let Messaging know about the message, for Analytics
	// [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
	
	// Print message ID.
	if (userInfo[kGCMMessageIDKey]) {
		NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
	}
	
	// Print full message.
	NSLog(@"willPresentNotification: %@", userInfo);
	
	// Change this to your preferred presentation option
	completionHandler(UNNotificationPresentationOptionNone);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
		 withCompletionHandler:(void(^)(void))completionHandler {
	NSDictionary *userInfo = response.notification.request.content.userInfo;
	if (userInfo[kGCMMessageIDKey]) {
		NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
	}
	
	// Print full message.
	NSLog(@"didReceiveNotificationResponse: %@", userInfo);
	
	completionHandler();
}

// Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
// To enable direct data messages, you can set [Messaging messaging].shouldEstablishDirectChannel to YES.
- (void)messaging:(FIRMessaging *)messaging didReceiveMessage:(FIRMessagingRemoteMessage *)remoteMessage {
	NSMutableArray *messageList = [self.accountList[0] messageList];
	MessageDataHandler *messageDataHandler = [[MessageDataHandler alloc] init];
	[messageDataHandler handleRemoteMessage:remoteMessage forList:messageList];
}


@end
