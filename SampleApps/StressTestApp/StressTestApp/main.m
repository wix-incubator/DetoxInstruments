//
//  main.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@import DTXProfiler;

int main(int argc, char * argv[]) {
	@autoreleasepool {
//		DTXMutableProfilingConfiguration* config = [DTXMutableProfilingConfiguration defaultProfilingConfiguration];
//		config.recordingFileURL = [NSURL fileURLWithPath:@"/Users/lnatan/Desktop/123.dtxprof"];
//		
//		DTXProfiler* _ = [DTXProfiler new];
//		[_ continueProfilingWithConfiguration:config];
//		
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//			[_ stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
//				NSLog(@"👹");
//			}];
//		});
		
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}
