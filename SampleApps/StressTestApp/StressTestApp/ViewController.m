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

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
	NSData* data = [[NSMutableData alloc] initWithLength:10 * 1024 * 1024];
	[data writeToFile:@"/Users/lnatan/Desktop/largeFile.dat" atomically:YES];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue
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


@end
