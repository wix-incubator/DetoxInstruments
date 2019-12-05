//
//  ViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "ViewController.h"
#import "AppURLProtocol.h"
#import "AppDelegate.h"
#import <StressTestApp-Swift.h>

#import <DTXProfiler/DTXProfiler.h>

@import Darwin;

#define DTX_DEBUG_EVENTS_CREATE_RECORDING 0

os_log_t __log_disk;
os_log_t __log_network;
os_log_t __log_general;

void (*untracked_for_demo_dispatch_after)(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);

@interface ViewController () <NSURLSessionDataDelegate>

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
	__log_network = os_log_create("com.LeoNatan.StressTestApp", "Network");
	__log_general = os_log_create("com.LeoNatan.StressTestApp", "Stress Test App");
	
	untracked_for_demo_dispatch_after = dlsym(RTLD_DEFAULT, "untracked_dispatch_after");
	if(untracked_for_demo_dispatch_after == NULL)
	{
		untracked_for_demo_dispatch_after = dispatch_after;
	}
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
	[SwiftSlower slowOnMainThread];
}

- (IBAction)_slowMyBackgroundTapped:(id)sender
{
	[SwiftSlower slowOnBackgroundThread];
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
	config.HTTPMaximumConnectionsPerHost = 200;
	if(_useProtocolSwitch.isOn)
	{
		NSMutableArray* protocols = config.protocolClasses.mutableCopy;
		[protocols insertObject:[AppURLProtocol class] atIndex:0];
		config.protocolClasses = protocols;
	}
	
	NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
	
	os_signpost_id_t nwIndex = os_signpost_id_generate(__log_network);
	os_signpost_interval_begin(__log_network, nwIndex, "Requesting Index");
	DTXEventIdentifier indexEvent = DTXProfilerMarkEventIntervalBegin(@"Network", @"Requesting Index", nil);
	
	[[session dataTaskWithURL:[NSURL URLWithString:@"https://jsonplaceholder.typicode.com/photos"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		DTXProfilerMarkEventIntervalEnd(indexEvent, error ? DTXEventStatusError : DTXEventStatusCompleted, error.localizedDescription);
		os_signpost_interval_end(__log_network, nwIndex, "Requesting Index");
		
		if(error)
		{
			return;
		}
		
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
				
				DTXProfilerMarkEventIntervalEnd(itemRequest, error ? DTXEventStatusError : DTXEventStatusCompleted, error.localizedDescription);
				os_signpost_interval_end(__log_network, nwItem, "Requesting Item");
				
				if(error)
				{
					return;
				}

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
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			localAfter -= 1;
			[self _peform:block after:localAfter];
		});
	}
}

- (IBAction)exitTapped:(UIButton*)sender
{
	exit(0);
}

- (IBAction)bombardEvents:(UIButton*)sender
{
	os_signpost_id_t test = os_signpost_id_generate(__log_general);
	os_signpost_interval_begin(__log_general, test, "Events Bombardment");
	
#if DTX_DEBUG_EVENTS_CREATE_RECORDING
	DTXMutableProfilingConfiguration* config = [DTXMutableProfilingConfiguration defaultProfilingConfiguration];
	config.samplingInterval = 0.25;
	config.numberOfSamplesBeforeFlushToDisk = 1000;
	
	__block DTXProfiler* profiler = [DTXProfiler new];
	[profiler startProfilingWithConfiguration:config];
	
	untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
#endif
		DTXProfilerMarkEvent(@"Bombardment", @"JustAnEvent", DTXEventStatusCancelled, @"Info");
		
		NSMutableArray* events = [NSMutableArray new];
		
		for(NSUInteger idx = 0; idx < 5000; idx++)
		{
			id event = DTXProfilerMarkEventIntervalBegin(@"Bombardment", [NSString stringWithFormat:@"%@", @(idx % 10)], [NSString stringWithFormat:@"%@", @(idx)]);
			[events addObject:event];
		}

		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[events enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				DTXProfilerMarkEventIntervalEnd(obj, DTXEventStatusCompleted, nil);
			}];
#if DTX_DEBUG_EVENTS_CREATE_RECORDING
			untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[profiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
					profiler = nil;
					
					os_signpost_interval_end(__log_general, test, "Starting Bombardment");
				}];
			});
#endif
		});
#if DTX_DEBUG_EVENTS_CREATE_RECORDING
	});
#endif
}

- (IBAction)startDemoTapped:(UIButton*)sender
{
	[sender setEnabled:NO];
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	
	__block DTXProfiler* __profiler = [DTXProfiler new];
#if DEBUG
	[__profiler setValue:@YES forKey:@"_cleanForDemo"];
#endif
	DTXMutableProfilingConfiguration* conf = DTXMutableProfilingConfiguration.defaultProfilingConfiguration;
	conf.samplingInterval = 0.25;
	conf.recordThreadInformation = YES;
	conf.collectStackTraces = YES;
	conf.symbolicateStackTraces = YES;
	conf.recordLogOutput = YES;
	conf.collectOpenFileNames = YES;
	conf.recordNetwork = YES;
	conf.disableNetworkCache = YES;
	conf.recordActivity = YES;
#if TARGET_OS_SIMULATOR
	conf.recordingFileURL = [[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSRCROOT"]] URLByAppendingPathComponent:@"../../Documentation/Example Recording/example.dtxrec"].URLByStandardizingPath;
#endif
	
	[__profiler startProfilingWithConfiguration:conf];
	
	[self _peform:^{
		os_signpost_id_t test = os_signpost_id_generate(__log_general);
		os_signpost_interval_begin(__log_general, test, "Starting Test");
		DTXEventIdentifier startingTest = DTXProfilerMarkEventIntervalBegin(@"Stress Test", @"Starting Test", nil);
		
		[self _slowMyBackgroundTapped:nil];
		
		NSTimeInterval timeline = 0;
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
			[self _slowMyBackgroundTapped:nil];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 4) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyDeviceTapped:nil];
		});
			
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 9.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self performSegueWithIdentifier:@"LNOpenWebView" sender:nil];
		});
		
#if ! TARGET_OS_MACCATALYST
		AppDelegate* ad = (id)UIApplication.sharedApplication.delegate;
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/search?tbm=isch&source=hp&biw=1445&bih=966&q=labrador+puppy&oq=doberman+puppy&gs_l=img.12...0.0.1.179.0.0.0.0.0.0.0.0..0.0....0...1..64.img..0.0.0.kg6uB2QOnS0"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0]];
		});
		
		const NSTimeInterval scrollDelta = 1.303;
		CGFloat scrollModifier = 3.0;
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += scrollDelta) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[ad.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.scrollBy(0, %@)", @(scrollModifier * UIScreen.mainScreen.bounds.size.height)]];
		});
#endif
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[[(UINavigationController*)self.presentedViewController topViewController] performSegueWithIdentifier:@"LNUnwindToMain" sender:nil];
		});
						
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
								
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
			[self _writeToDisk:nil];
		});
									
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 0.25) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _writeToDisk:nil];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self startNetworkRequestsTapped:nil];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 5.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyDeviceTapped:nil];
		});
		
		untracked_for_demo_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeline += 10.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self.startDemoButton setTitle:@"Start Demo" forState:UIControlStateNormal];
			[self.startDemoButton setEnabled:YES];
			
			DTXProfilerMarkEventIntervalEnd(startingTest, DTXEventStatusCompleted, nil);
			os_signpost_interval_end(__log_general, test, "Starting Test");
			
			[__profiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
				NSLog(@"%@", conf.recordingFileURL);
#if TARGET_OS_SIMULATOR
				NSError* err;
				[NSFileManager.defaultManager removeItemAtURL:[[conf.recordingFileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"example.dtxrec.zip"] error:&err];
#endif
				
				__profiler = nil;
			}];
		});
	} after:1.0];
}

- (void)_startRecordnigWithTimeInterval:(NSTimeInterval)ti sender:(UIButton*)sender
{
	[sender setEnabled:NO];
	
	__block DTXProfiler* __profiler = [DTXProfiler new];
	DTXMutableProfilingConfiguration* conf = DTXMutableProfilingConfiguration.defaultProfilingConfiguration;
//	conf.recordPerformance = NO;
	conf.samplingInterval = 0.25;
	conf.recordThreadInformation = YES;
	conf.collectStackTraces = YES;
	conf.symbolicateStackTraces = YES;
	conf.recordLogOutput = YES;
	conf.collectOpenFileNames = YES;
	conf.recordNetwork = YES;
	conf.disableNetworkCache = YES;
	conf.recordActivity = YES;
#if TARGET_OS_SIMULATOR
	conf.recordingFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Users/lnatan/Desktop/%@seconds.dtxrec", @(ti)]].URLByStandardizingPath;
#endif
	
	[__profiler startProfilingWithConfiguration:conf duration:ti completionHandler:^(NSError * _Nullable error) {
		NSLog(@"%@", conf.recordingFileURL);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[sender setEnabled:YES];
		});
	}];
}

- (IBAction)start10SecRecording:(UIButton*)sender
{
	[self _startRecordnigWithTimeInterval:10 sender:sender];
}

- (IBAction)start30SecRecording:(UIButton*)sender
{
	[self _startRecordnigWithTimeInterval:30 sender:sender];
}

@end
