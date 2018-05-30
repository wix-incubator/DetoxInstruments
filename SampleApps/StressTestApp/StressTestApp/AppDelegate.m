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
{
	dispatch_source_t _consoleLogDemoTimerSource;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSArray<NSString*>* exampleLogOutputs = @[ @"[CLIoHidInterface] Refreshing service refs",
											   @"Fetching effective device orientation with temporary manager: faceUp (5)",
											   @"Updating device orientation from CoreMotion to: faceUp (5)",
											   @"-[BrightnessSystemInternal copyPropertyForKey:client:]: client=4304426368 key=<private>",
											   @"[BKEventFocusManager] Setting foreground application to: com.apple.mobilesafari (337)",
											   @"EventStatistics.m:48  :   11229.47800:  Info: 2 Button since   11182.09352 (Wed May 30 12:17:12 2018)",
											   @"CoreAnimation: updates deferred for too long",
											   @"Ping timer fired, resetting watchdog",
											   @"Apple Keyboard char: 0 symbol: 0 spacebar: 0 arrow: 0 cursor: 0 modifier: 0",
											   @"Cover HES open: 0 close: 0 <50ms: 0 50-100ms: 0 100-250ms: 0 250-500ms: 0 500-1000ms: 0",
											   @"[pid:40] HID activity: 1 -> 0 (service:0x0 event:0)",
											   @"Ping timer fired, resetting watchdog",
											   @"Got power notification 3758097008",
											   @"Got kIOMessageCanSystemSleep",
											   @"Got power notification 3758097024",
											   @"Got kIOMessageSystemWillSleep", ];
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
	_consoleLogDemoTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("com.wix.ConsoleOutputDemo", qosAttribute));
	uint64_t interval = 0.5 * NSEC_PER_SEC;
	dispatch_source_set_timer(_consoleLogDemoTimerSource, dispatch_walltime(NULL, 0), interval, interval / 10);
	
	dispatch_source_set_event_handler(_consoleLogDemoTimerSource, ^{
		NSLog(@"%@", exampleLogOutputs[arc4random_uniform((uint32_t)exampleLogOutputs.count)]);
	});
	
	dispatch_resume(_consoleLogDemoTimerSource);
	
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

@end
