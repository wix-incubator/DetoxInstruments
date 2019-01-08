//
//  AppDelegate.h
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WebKit;
#import <os/signpost.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (weak, nonatomic) UIWebView* webView;
#pragma clang diagnostic pop


@end

