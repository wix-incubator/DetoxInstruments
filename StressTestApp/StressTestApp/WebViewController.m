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
	
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?site=&tbm=isch&source=hp&biw=1680&bih=989&q=Donald+Trump+meme&oq=Donald+Trump+meme&gs_l=img.3..0l10.915.3197.0.3389.18.14.0.0.0.0.280.1632.0j9j1.10.0....0...1.1.64.img..8.10.1632.0.Ov-oXERATfs#tbm=isch&q=donald+trump+president+meme"]]];
}

@end
