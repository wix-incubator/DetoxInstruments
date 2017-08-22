//
//  WebViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController
{
	IBOutlet UIWebView* _webView;
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
	return NO;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?biw=1680&bih=989&tbm=isch&sa=1&q=labrador+puppy&oq=labrador+puppy&gs_l=psy-ab.3..0l4.1212.2330.0.2473.8.8.0.0.0.0.160.570.0j4.4.0....0...1.1.64.psy-ab..5.3.409...0i7i30k1j0i67k1.Mo__QkCCpAw"]]];
}

@end
