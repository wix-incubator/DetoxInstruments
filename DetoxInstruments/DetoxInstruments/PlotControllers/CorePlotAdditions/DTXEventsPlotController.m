//
//  DTXEventsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXEventsPlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXSignpostDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXEventsPlotController

+ (Class)UIDataProviderClass
{
	return [DTXSignpostDataProvider class];
}

+ (Class)classForIntervalSamples
{
	return [DTXSignpostSample class];
}

//- (NSArray<NSSortDescriptor *> *)sortDescriptors
//{
//	return @[[NSSortDescriptor sortDescriptorWithKey:@"isEvent" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
//}

- (NSString *)displayName
{
	return NSLocalizedString(@"Events", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Events instrument captures information about events marked by the developer of the profiled app.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"Events"];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"totalDataLength"];
}

- (NSArray<NSString*>*)propertiesToFetch;
{
	return @[@"timestamp", @"endTimestamp", @"isEvent", @"eventStatus"];
}

- (NSArray<NSString*>*)relationshipsToFetch
{
	return @[@"recording"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.signpostPlotControllerColor];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

- (NSDate*)endTimestampForSample:(DTXSignpostSample*)sample
{
	if(sample.duration == 0)
	{
		return [sample.timestamp dateByAddingTimeInterval:0.00001];
	}
	
	return sample.endTimestamp ?: [sample.timestamp dateByAddingTimeInterval:1];
}

- (NSColor*)colorForSample:(DTXSignpostSample*)sample
{
	return sample.plotControllerColor;
}

@end
