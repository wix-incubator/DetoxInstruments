//
//  DTXEventsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXEventsPlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXSignpostDataProvider.h"
#import "DTXSignpostFlatDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXDetailController.h"

@implementation DTXEventsPlotController

- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	NSMutableArray* rv = [NSMutableArray new];
	
	DTXDetailController* flatController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	flatController.detailDataProvider = [[DTXSignpostFlatDataProvider alloc] initWithDocument:self.document plotController:self];
	
	[rv addObject:flatController];
	
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		DTXDetailController* detailController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
		detailController.detailDataProvider = [[DTXSignpostDataProvider alloc] initWithDocument:self.document plotController:self];
		
		[rv insertObject:detailController atIndex:0];
	}
	
	return rv;
}

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

- (NSString *)helpTopicName
{
	return @"Events";
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
	return sample.defactoEndTimestamp;
}

- (NSColor*)colorForSample:(DTXSignpostSample*)sample
{
	return sample.plotControllerColor;
}

- (NSString*)titleForSample:(DTXSignpostSample*)sample
{
	NSMutableString* rv = sample.name.mutableCopy;
	
	if(sample.additionalInfoStart.length > 0)
	{
		[rv appendFormat:@" (%@)", sample.additionalInfoStart];
	}
	
	return rv;
}

@end
