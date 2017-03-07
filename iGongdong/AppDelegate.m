//
//  AppDelegate.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "AppDelegate.h"
#import "Utils.h"
#import "LoginToService.h"
#import "ArticleView.h"

@interface AppDelegate ()
{
	NSDictionary *dUserInfo; //To storage the push data
}
@end

@implementation AppDelegate

@synthesize strDevice;
@synthesize strUserId;
@synthesize switchPush;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
	//	[[UIApplication sharedApplication] cancelAllLocalNotifications];
	
	// Register for Remote Notifications
	BOOL pushEnable = NO;
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
		pushEnable = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
	}
	
	// 푸시 아이디를 달라고 폰에다가 요청하는 함수
	//	UIApplication *application = [UIApplication sharedApplication];
	if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
		NSLog(@"upper ios8");
		// iOS 8 Notifications
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
		[application registerForRemoteNotifications];
	}
	
	// 앱이 완전히 종료된 상태에서 푸쉬 알림을 받으면 해당 푸쉬 알림 메시지가 launchOptions 에 포함되어서 실행된다.
	if (launchOptions) {
		dUserInfo = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dUserInfo) {
			[self moveToViewController];
		}
	}
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSLog(@"Did Register for Remote Notifications with Device Token (%@)", deviceToken);
	strDevice = [[[[deviceToken description]
							stringByReplacingOccurrencesOfString:@"<"withString:@""]
				  stringByReplacingOccurrencesOfString:@">" withString:@""]
				 stringByReplacingOccurrencesOfString: @" " withString: @""];
	NSLog(@"converted device Device Token (%@)", strDevice);
	
	LoginToService *login = [[LoginToService alloc] init];
	[login PushRegister];
	
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Did Fail to Register for Remote Notifications");
	NSLog(@"%@, %@", error, error.localizedDescription);
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo  {
	NSLog(@"remote notification: %@",[userInfo description]);
	
	if (userInfo) {
		NSLog(@"%@",userInfo);
		dUserInfo = userInfo;
	}
	
	/*	앱이 실행중일때 아래 코드를 추가하면 푸쉬 알림을 받아 바로 해당 글로 이동한다.
	 중간에 새로운 글이 추가되었다고 해당 글을 보겠느냐는 알림을 보여준 뒤 	이동해야 할 것 같음.
	 */
	/*	if ([UIApplication sharedApplication].applicationState ==
		UIApplicationStateActive) {
		[self moveToViewController];
	 }
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSLog(@"applicationDidBecomeActive");
	//Data from the push.
	if (dUserInfo != nil) {
		[self moveToViewController];
	}
}

-(void)moveToViewController {
	//Do whatever you need
	NSLog(@"applicationDidBecomeActive with UserInfo");
	
	NSString *commId;
	NSString *boardId;
	NSString *boardNo;
	if ([dUserInfo objectForKey:@"commId"]) {
		commId = [dUserInfo objectForKey:@"commId"];
		boardId = [dUserInfo objectForKey:@"boardId"];
		boardNo = [dUserInfo objectForKey:@"boardNo"];
	} else {
		dUserInfo = nil;
		return;
	}
	
	if ([boardId isEqualToString:@""] || [boardNo isEqualToString:@""]) {
		dUserInfo = nil;
		return;
	}
	
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
	
	ArticleView *viewController = (ArticleView*)[storyboard instantiateViewControllerWithIdentifier:@"ArticleView"];
	if (viewController != nil) {
		viewController.m_strCommId = commId;
		viewController.m_strBoardId = boardId;
		viewController.m_strBoardNo = boardNo;
		viewController.target = nil;
		viewController.selector = nil;
	} else {
		return;
	}
	
	//		[self.window.rootViewController presentViewController:viewController animated:YES completion:NULL];
	
	UINavigationController *navController = (UINavigationController*)self.window.rootViewController;
	if (navController != nil) {
		[navController pushViewController:viewController animated:YES];
	}
	dUserInfo = nil;
}

@end
