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

os_log_t __log_disk;
os_log_t __log_cpu_stress;
os_log_t __log_network;
os_log_t __log_general;

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UISwitch* useProtocolSwitch;
@property (nonatomic, weak) IBOutlet UIButton* startDemoButton;

@end

@implementation ViewController
{
	BOOL darkMode;
}

+ (void)load
{
	__log_disk = os_log_create("com.LeoNatan.StressTestApp", "Disk");
	__log_cpu_stress = os_log_create("com.LeoNatan.StressTestApp", "CPU Stress");
	__log_network = os_log_create("com.LeoNatan.StressTestApp", "Network");
	__log_general = os_log_create("com.LeoNatan.StressTestApp", "Stress Test App");
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
	os_signpost_id_t slowFg = os_signpost_id_generate(__log_cpu_stress);
	os_signpost_interval_begin(__log_cpu_stress, slowFg, "Slow Foreground");
	DTXEventIdentifier slowForeground = DTXProfilerMarkEventIntervalBegin(@"CPU Stress", @"Slow Foreground", nil);
	
	NSDate* before = [NSDate date];
	
	while([before timeIntervalSinceNow] > -5)
	{
		//These are a torture test for Detox Instruments performance profiling.
		
//		os_signpost_event_emit(__log_cpu_stress, OS_SIGNPOST_ID_EXCLUSIVE, "Slow Foreground Inside While");
//		DTXProfilerMarkEvent(@"CPU Stress", @"Slow Foreground Inside While", DTXEventStatusCategory1, nil);
	}
	
	DTXProfilerMarkEventIntervalEnd(slowForeground, DTXEventStatusCompleted, nil);
	os_signpost_interval_end(__log_cpu_stress, slowFg, "Slow Foreground");
}

- (IBAction)_slowMyBackgroundTapped:(id)sender
{
	os_signpost_id_t slowBg = os_signpost_id_generate(__log_cpu_stress);
	os_signpost_interval_begin(__log_cpu_stress, slowBg, "Slow Background");
	
	DTXEventIdentifier slowBackground = DTXProfilerMarkEventIntervalBegin(@"CPU Stress", @"Slow Background", nil);
	
	NSDate* before = [NSDate date];
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		while([before timeIntervalSinceNow] > -10)
		{
			//These are a torture test for Detox Instruments performance profiling.
			
//			os_signpost_event_emit(__log_cpu_stress, OS_SIGNPOST_ID_EXCLUSIVE, "Slow Background Inside While");
//			DTXProfilerMarkEvent(@"CPU Stress", @"Slow Background Inside While", DTXEventStatusCategory1, nil);
		}
		
		DTXProfilerMarkEventIntervalEnd(slowBackground, DTXEventStatusCompleted, nil);
		os_signpost_interval_end(__log_cpu_stress, slowBg, "Slow Background");
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
	
	os_signpost_id_t nwIndex = os_signpost_id_generate(__log_network);
	os_signpost_interval_begin(__log_network, nwIndex, "Requesting Index");
	DTXEventIdentifier indexEvent = DTXProfilerMarkEventIntervalBegin(@"Network", @"Requesting Index", nil);
	
	[[session dataTaskWithURL:[NSURL URLWithString:@"https://jsonplaceholder.typicode.com/photos"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if(error)
		{
			DTXProfilerMarkEventIntervalEnd(indexEvent, DTXEventStatusError, error.localizedDescription);
			os_signpost_interval_end(__log_network, nwIndex, "Requesting Index");
			return;
		}
		
		DTXProfilerMarkEventIntervalEnd(indexEvent, DTXEventStatusCompleted, nil);
		os_signpost_interval_end(__log_network, nwIndex, "Requesting Index");
		
		NSArray* arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
		__block NSUInteger executedRequests = 0;
		[arr enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(executedRequests > 50)
			{
				*stop = YES;
			}
			
			executedRequests++;
			
			os_signpost_id_t nwItem = os_signpost_id_generate(__log_network);
			os_signpost_interval_begin(__log_network, nwItem, "Requesting Item");
			DTXEventIdentifier itemRequest = DTXProfilerMarkEventIntervalBegin(@"Network", @"Requesting Item", obj[@"thumbnailUrl"]);
			
			[[session dataTaskWithURL:[NSURL URLWithString:obj[@"thumbnailUrl"]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
				if(error)
				{
					DTXProfilerMarkEventIntervalEnd(itemRequest, DTXEventStatusError, error.localizedDescription);
					os_signpost_interval_end(__log_network, nwItem, "Requesting Item");
					return;
				}
				
				DTXProfilerMarkEventIntervalEnd(itemRequest, DTXEventStatusCompleted, nil);
				os_signpost_interval_end(__log_network, nwItem, "Requesting Item");
				NSLog(@"Got data with length: %@", @(data.length));
			}] resume];
		}];
	}] resume];
}

- (IBAction)_writeToDisk:(id)sender
{
	os_signpost_id_t disk = os_signpost_id_generate(__log_disk);
	os_signpost_interval_begin(__log_disk, disk, "Write to Disk");
	DTXEventIdentifier writeToDisk = DTXProfilerMarkEventIntervalBegin(@"Disk", @"Write to Disk", nil);
	
	NSData* data = [[NSMutableData alloc] initWithLength:20 * 1024 * 1024];
	
	[data writeToURL:[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"largeFile.dat"] atomically:YES];
	
	DTXProfilerMarkEventIntervalEnd(writeToDisk, DTXEventStatusCompleted, nil);
	os_signpost_interval_end(__log_disk, disk, "Write to Disk");
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
	
	__block DTXProfiler* __profiler = [DTXProfiler new];
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
	
	[__profiler startProfilingWithConfiguration:conf];
	
	[self _peform:^{
		os_signpost_id_t test = os_signpost_id_generate(__log_general);
		os_signpost_interval_begin(__log_general, test, "Starting Test");
		DTXEventIdentifier startingTest = DTXProfilerMarkEventIntervalBegin(@"Stress Test", @"Starting Test", nil);
		
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
			
			DTXProfilerMarkEventIntervalEnd(startingTest, DTXEventStatusCompleted, nil);
			os_signpost_interval_end(__log_general, test, "Starting Test");
			
			[__profiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
				NSLog(@"%@", conf.recordingFileURL);
#if TARGET_OS_SIMULATOR
				NSError* err;
				[NSFileManager.defaultManager removeItemAtURL:[[conf.recordingFileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"example.dtxprof.zip"] error:&err];
#endif
				
				__profiler = nil;
			}];
		});
	} after:1.0];
}

@end
