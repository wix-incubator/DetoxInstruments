//
//  DTXAcknowledgementsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXAcknowledgementsViewController.h"
@import WebKit;

@interface DTXAcknowledgementsViewController () <WKNavigationDelegate> @end

@implementation DTXAcknowledgementsViewController
{
	IBOutlet __weak WKWebView* _webView;
	NSURL* _htmlURL;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_htmlURL = [[NSBundle mainBundle] URLForResource:@"Acknowledgements" withExtension:@"html"];
	
	[_webView loadFileURL:_htmlURL allowingReadAccessToURL:_htmlURL];
	_webView.navigationDelegate = self;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
{
	if([navigationAction.request.URL isEqualTo:_htmlURL])
	{
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}
	
	[[NSWorkspace sharedWorkspace] openURL:navigationAction.request.URL];
	decisionHandler(WKNavigationActionPolicyCancel);
}

@end
