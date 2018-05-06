//
//  ViewController.m
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "ViewController.h"
#import "AppURLProtocol.h"

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
	
	[[UIPasteboard generalPasteboard] setItems:@[@{UIPasteboardTypeAutomatic: [[NSAttributedString alloc] initWithString:@"Hello Bold World" attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:20]}]}, @{UIPasteboardTypeAutomatic: [[NSAttributedString alloc] initWithString:@"Hello Bold World 2" attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:20]}]}, @{UIPasteboardTypeAutomatic: [[NSAttributedString alloc] initWithString:@"Hello Bold World 3" attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:20]}]}]];
	
//	[[UIPasteboard generalPasteboard] setData: forPasteboardType:UIPasteboardTypeAutomatic];
	
//	[[UIPasteboard generalPasteboard] setImages:@[[UIImage imageNamed:@"image1"], [UIImage imageNamed:@"image2"], [UIImage imageNamed:@"image3"]]];
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
	
	[self _peform:^{
		[self _slowMyBackgroundTapped:nil];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self _slowMyBackgroundTapped:nil];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self _slowMyBackgroundTapped:nil];
			});
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self _slowMyBackgroundTapped:nil];
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[self performSegueWithIdentifier:@"LNOpenWebView" sender:nil];
					
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
						[[(UINavigationController*)self.presentedViewController topViewController] performSegueWithIdentifier:@"LNUnwindToMain" sender:nil];
						
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
							[self _writeToDisk:nil];
							[self _writeToDisk:nil];
							[self _writeToDisk:nil];
							[self _writeToDisk:nil];
							[self _writeToDisk:nil];
							
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
								[self _writeToDisk:nil];
								[self _writeToDisk:nil];
								
								dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
									[self startNetworkRequestsTapped:nil];
									
									dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
										[self.startDemoButton setTitle:@"Start Demo" forState:UIControlStateNormal];
										[self.startDemoButton setEnabled:YES];
									});
								});
							});
						});
					});
				});
			});
		});
	} after:10];
}

@end
