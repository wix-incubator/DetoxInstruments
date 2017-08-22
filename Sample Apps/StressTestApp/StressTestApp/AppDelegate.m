//
//  AppDelegate.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "AppDelegate.h"
#import <DTXProfiler/DTXProfiler.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

DTXProfiler* __;
+ (void)load
{
//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
////	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//		__ = [NSClassFromString(@"DTXProfiler") new];
//		DTXProfilingConfiguration* conf = [DTXProfilingConfiguration defaultProfilingConfiguration];
//		conf.recordThreadInformation = YES;
//		conf.collectStackTraces = YES;
//		conf.symbolicateStackTraces = YES;
//		conf.collectJavaScriptStackTraces = YES;
//		conf.symbolicateJavaScriptStackTraces = YES;
//		[__ startProfilingWithConfiguration:conf];
//
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//			[__ stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
//				NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
//			}];
//		});
//	});
	
//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//		[__ pushSampleGroupWithName:@"Group 1"];
//
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//			[__ pushSampleGroupWithName:@"Group 1.1"];
//
//			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//				[__ pushSampleGroupWithName:@"Group 1.1.1"];
//
//				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//					[__ pushSampleGroupWithName:@"Group 1.1.1.1"];
//
//					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//						[__ popSampleGroup];
//						[__ popSampleGroup];
//						[__ popSampleGroup];
//						[__ popSampleGroup];
//
//						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//							[__ pushSampleGroupWithName:@"Group 2"];
//
//							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//								[__ stopProfiling];
//							});
//						});
//					});
//				});
//			});
//		});
//	});
	
//	[NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
//		NSLog(@"%@ %@", [NSDate date], arc4random_uniform(20) < 10 ? @"(single line)" : @{@"a": @"b", @"c": @"d", @"e": @"f"});
//	}];
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

@end
