//
//  WebViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "WebViewController.h"
#import <DTXProfiler/DTXEvents.h>
#import "AppDelegate.h"

os_log_t __log_web_view;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface LNWebView : UIWebView

@end
#pragma clang diagnostic pop

@implementation LNWebView

+ (void)load
{
	__log_web_view = os_log_create("com.LeoNatan.StressTestApp", "Web View");
}

- (void)loadRequest:(NSURLRequest *)request
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Loading Web Page");
	DTXProfilerMarkEvent(@"Web", @"Loading Web Page", DTXEventStatusCategory4, request.URL.absoluteString);
	
	[super loadRequest:request];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Evaluating JavaScript String");
	DTXProfilerMarkEvent(@"Web", @"Evaluating JavaScript String", DTXEventStatusCategory4, script);
	
	return [super stringByEvaluatingJavaScriptFromString:script];
}

@end

@interface WebViewController ()

@end

@implementation WebViewController
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	IBOutlet UIWebView* _webView;
#pragma clang diagnostic pop
}

- (void)viewDidLoad
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Web View Loaded");
	DTXProfilerMarkEvent(@"Web", @"Web View Loaded", DTXEventStatusCategory4, nil);
	
	[super viewDidLoad];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?tbm=isch&source=hp&biw=1445&bih=966&q=labrador+puppy&oq=labrador+puppy&gs_l=img.12...0.0.1.179.0.0.0.0.0.0.0.0..0.0....0...1..64.img..0.0.0.kg6uB2QOnS0"]]];
}

- (void)viewDidAppear:(BOOL)animated
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Web View Appeared");
	DTXProfilerMarkEvent(@"Web", @"Web View Appeared", DTXEventStatusCategory4, nil);
	
	[super viewDidAppear:animated];
	
	AppDelegate* ad = (id)UIApplication.sharedApplication.delegate;
	ad.webView = _webView;
}

@end
