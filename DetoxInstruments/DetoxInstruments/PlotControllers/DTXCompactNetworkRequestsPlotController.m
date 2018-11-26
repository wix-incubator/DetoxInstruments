//
//  DTXCompactNetworkRequestsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXNetworkSample+CoreDataClass.h"
#import "DTXNetworkDataProvider.h"
#import "DTXRecording+UIExtensions.h"

@implementation DTXCompactNetworkRequestsPlotController

+ (Class)UIDataProviderClass
{
	return [DTXNetworkDataProvider class];
}

+ (Class)classForIntervalSamples
{
	return [DTXNetworkSample class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Network Activity", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Network Activity instrument captures information about the profiled app's network activity.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"NetworkActivity"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"totalDataLength"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.networkRequestsPlotControllerColor];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

- (NSDate*)endTimestampForSample:(DTXNetworkSample*)sample
{
	return sample.responseTimestamp ?: [sample.timestamp dateByAddingTimeInterval:1];
}

- (NSColor*)colorForSample:(DTXNetworkSample*)sample
{
	NSColor* lineColor = NSColor.successColor;
	
	if(sample.responseStatusCode == 0)
	{
		lineColor = NSColor.warningColor;
	}
	else if(sample.responseStatusCode < 200 || sample.responseStatusCode >= 400)
	{
		lineColor = NSColor.warning2Color;
	}
	
	if(sample.responseError)
	{
		lineColor = NSColor.warning3Color;
	}
	
	return lineColor;
}

@end

