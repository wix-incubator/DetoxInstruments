//
//  DTXSignpostPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostPlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXSignpostDataProvider.h"

@implementation DTXSignpostPlotController

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
	return NSLocalizedString(@"The Events instrument captures information about events marked by the app.", @"");
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
	return sample.isEvent ? sample.timestamp : sample.endTimestamp ?: NSDate.distantFuture;
}

- (NSDate*)endTimestampForSampleForSorting:(DTXSignpostSample*)sample
{
	return sample.isEvent ? /*[*/ sample.timestamp /*dateByAddingTimeInterval:1]*/ : sample.endTimestamp ?: NSDate.distantFuture;
}

- (NSColor*)colorForSample:(DTXSignpostSample*)sample
{
	return [NSColor signpostPlotControllerColorForCategory:sample.eventStatus];
}

@end
