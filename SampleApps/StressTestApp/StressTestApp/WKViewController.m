//
//  WKViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 1/28/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "WKViewController.h"
@import WebKit;

@interface WKViewController ()
{
	IBOutlet WKWebView* _webView;
}

@end

@implementation WKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?tbm=isch&source=hp&biw=1445&bih=966&q=cute+labrador+puppy&oq=labrador+puppy&gs_l=img.12...0.0.1.179.0.0.0.0.0.0.0.0..0.0....0...1..64.img..0.0.0.kg6uB2QOnS0"]]];
}

@end
