//
//  ViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "ViewController.h"
#import "AppURLProtocol.h"
#import "AppDelegate.h"

#import <DTXProfiler/DTXProfiler.h>

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UISwitch* useProtocolSwitch;
@property (nonatomic, weak) IBOutlet UIButton* startDemoButton;

@end

@implementation ViewController
{
	BOOL darkMode;
}

- (void)viewDidLoad
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LNDemoUserDarkMode"];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"LNDemoUserDarkMode"];
	
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	[self _updateLightDrak];
}

- (void)userDefaultsDidChange:(NSNotification*)note
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _updateLightDrak];
	});
}

- (void)_updateLightDrak
{
	BOOL newDarkMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"LNDemoUserDarkMode"];
	if(self->darkMode != newDarkMode)
	{
		self->darkMode = newDarkMode;
		[UIView animateWithDuration:0.15 animations:^{
			self.view.backgroundColor = self->darkMode ? UIColor.blackColor : UIColor.whiteColor;
			[self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				if([obj isKindOfClass:[UISwitch class]])
				{
					return;
				}
				
				[obj setTintColor: self->darkMode ? UIColor.whiteColor : self.view.window.tintColor];
				
				if([obj isKindOfClass:[UILabel class]])
				{
					[(UILabel*)obj setTextColor:self->darkMode ? UIColor.whiteColor : UIColor.blackColor];
				}
			}];
			[self setNeedsStatusBarAppearanceUpdate];
		} completion:nil];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return darkMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)_slowMyDeviceTapped:(id)sender
{
	NSDate* before = [NSDate date];
	
	while([before timeIntervalSinceNow] > -5);
}

- (IBAction)_slowMyBackgroundTapped:(id)sender
{
	NSDate* before = [NSDate date];
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		while([before timeIntervalSinceNow] > -10);
	});
}

- (IBAction)_clearCookies:(id)sender
{
	[NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[NSHTTPCookieStorage.sharedHTTPCookieStorage deleteCookie:obj];
	}];
}

- (IBAction)startNetworkRequestsTapped:(id)sender
{
	NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
	config.HTTPMaximumConnectionsPerHost = 2;
	if(_useProtocolSwitch.isOn)
	{
		NSMutableArray* protocols = config.protocolClasses.mutableCopy;
		[protocols insertObject:[AppURLProtocol class] atIndex:0];
		config.protocolClasses = protocols;
	}
	
	NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
	
	[[session dataTaskWithURL:[NSURL URLWithString:@"https://jsonplaceholder.typicode.com/photos"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		NSArray* arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
		__block NSUInteger executedRequests = 0;
		[arr enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(executedRequests > 50)
			{
				*stop = YES;
			}
			
			executedRequests++;
			
			[[session dataTaskWithURL:[NSURL URLWithString:obj[@"thumbnailUrl"]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
				NSLog(@"Got data with length: %@", @(data.length));
			}] resume];
		}];
	}] resume];
}

- (IBAction)_writeToDisk:(id)sender
{
	NSData* data = [[NSMutableData alloc] initWithLength:20 * 1024 * 1024];
	
	[data writeToURL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"largeFile.dat"] atomically:YES];
}

- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue
{
}

- (IBAction)protocolEnableSwitchDidChange:(UISwitch *)sender
{
	if(sender.isOn)
	{
		[NSURLProtocol registerClass:[AppURLProtocol class]];
	}
	else
	{
		[NSURLProtocol unregisterClass:[AppURLProtocol class]];
	}
}

- (void)_peform:(void(^)(void))block after:(NSTimeInterval)after
{
	__block NSTimeInterval localAfter = after;
	
	if(localAfter == 0)
	{
		[self.startDemoButton setTitle:@"Running" forState:UIControlStateNormal];
		block();
	}
	else
	{
		[self.startDemoButton setTitle:[NSString stringWithFormat:@"%@", @(localAfter)] forState:UIControlStateNormal];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			localAfter -= 1;
			[self _peform:block after:localAfter];
		});
	}
}

- (IBAction)startDemoTapped:(UIButton*)sender
{
	[sender setEnabled:NO];
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	
	DTXProfiler* __ = [NSClassFromString(@"DTXProfiler") new];
	DTXMutableProfilingConfiguration* conf = [DTXMutableProfilingConfiguration defaultProfilingConfiguration];
	conf.samplingInterval = 0.25;
	conf.recordThreadInformation = YES;
	conf.collectStackTraces = YES;
	conf.symbolicateStackTraces = YES;
	conf.recordLogOutput = YES;
	conf.collectOpenFileNames = YES;
	conf.recordNetwork = YES;
#if TARGET_OS_SIMULATOR
	conf.recordingFileURL = [[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSRCROOT"]] URLByAppendingPathComponent:@"../../Documentation/Example Recording/example.dtxprof"].URLByStandardizingPath;
#endif
	
	[__ startProfilingWithConfiguration:conf];
	
	
	[self _peform:^{
		[self _slowMyBackgroundTapped:nil];
		
		NSTimeInterval timeline = 0;
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 4) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyDeviceTapped:nil];
		});
			
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 9.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self performSegueWithIdentifier:@"LNOpenWebView" sender:nil];
		});
		
		AppDelegate* ad = (id)UIApplication.sharedApplication.delegate;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?tbm=isch&source=hp&biw=1445&bih=966&q=labrador+puppy&oq=doberman+puppy&gs_l=img.12...0.0.1.179.0.0.0.0.0.0.0.0..0.0....0...1..64.img..0.0.0.kg6uB2QOnS0"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0]];
		});
		
		const NSTimeInterval scrollDelta = 1.0;
		CGFloat scrollModifier = 2.0;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 1.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://nytimes.com"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[[(UINavigationController*)self.presentedViewController topViewController] performSegueWithIdentifier:@"LNUnwindToMain" sender:nil];
		});
						
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
								
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
									
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
		});
										
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self startNetworkRequestsTapped:nil];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyDeviceTapped:nil];
		});
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 10.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.startDemoButton setTitle:@"Start Demo" forState:UIControlStateNormal];
			[self.startDemoButton setEnabled:YES];
			
			[__ stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
				NSLog(@"%@", conf.recordingFileURL);
#if TARGET_OS_SIMULATOR
				NSError* err;
				[NSFileManager.defaultManager removeItemAtURL:[[conf.recordingFileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"example.dtxprof.zip"] error:&err];
#endif
			}];
		});
	} after:1.0];
}

@end
