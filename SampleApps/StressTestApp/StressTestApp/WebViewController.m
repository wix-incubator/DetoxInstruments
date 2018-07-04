//
//  WebViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "WebViewController.h"
#import <DTXProfiler/DTXProfiler.h>
#import "AppDelegate.h"

os_log_t __log_web_view;

@interface LNWebView : UIWebView

@end

@implementation LNWebView

+ (void)load
{
	__log_web_view = os_log_create("com.LeoNatan.StressTestApp", "Web View");
}

- (void)loadRequest:(NSURLRequest *)request
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Loading Web Page");
	[__profiler markEventWithCategory:@"Web" name:@"Loading Web Page" eventStatus:DTXEventStatusCategory4 additionalInfo:request.URL.absoluteString];
	
	[super loadRequest:request];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Evaluating JavaScript String");
	[__profiler markEventWithCategory:@"Web" name:@"Evaluating JavaScript String" eventStatus:DTXEventStatusCategory4 additionalInfo:script];
	
	return [super stringByEvaluatingJavaScriptFromString:script];
}

@end

@interface WebViewController ()

@end

@implementation WebViewController
{
	IBOutlet UIWebView* _webView;
}

- (void)viewDidLoad
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Web View Loaded");
	[__profiler markEventWithCategory:@"Web" name:@"Web View Loaded" eventStatus:DTXEventStatusCategory4 additionalInfo:nil];
	
	[super viewDidLoad];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?tbm=isch&source=hp&biw=1445&bih=966&q=labrador+puppy&oq=labrador+puppy&gs_l=img.12...0.0.1.179.0.0.0.0.0.0.0.0..0.0....0...1..64.img..0.0.0.kg6uB2QOnS0"]]];
}

- (void)viewDidAppear:(BOOL)animated
{
	os_signpost_event_emit(__log_web_view, OS_SIGNPOST_ID_EXCLUSIVE, "Web View Appeared");
	[__profiler markEventWithCategory:@"Web" name:@"Web View Appeared" eventStatus:DTXEventStatusCategory4 additionalInfo:nil];
	
	[super viewDidAppear:animated];
	
	AppDelegate* ad = (id)UIApplication.sharedApplication.delegate;
	ad.webView = _webView;
}

@end
