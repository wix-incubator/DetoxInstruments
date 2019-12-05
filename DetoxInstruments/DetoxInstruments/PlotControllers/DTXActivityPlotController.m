//
//  DTXActivityPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXActivityPlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXActivityFlatDataProvider.h"
#import "DTXActivitySummaryDataProvider.h"
#import "DTXDetailController.h"
#endif
#import "DTXActivitySample+UIExtensions.h"
#import "DTXIntervalSamplePlotController-Private.h"

@implementation DTXActivityPlotController

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super _initWithDocument:document isForTouchBar:isForTouchBar sectionConfigurator:nil];
	
	return self;
}

#if ! PROFILER_PREVIEW_EXTENSION
- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	NSMutableArray* rv = [NSMutableArray new];

	DTXDetailController* flatController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	flatController.detailDataProvider = [[DTXActivityFlatDataProvider alloc] initWithDocument:self.document plotController:self];
	
	[rv addObject:flatController];
	
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		DTXDetailController* detailController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
		detailController.detailDataProvider = [[DTXActivitySummaryDataProvider alloc] initWithDocument:self.document plotController:self];
		
		[rv insertObject:detailController atIndex:0];
	}
	
	return rv;
}

+ (Class)UIDataProviderClass
{
	return [DTXActivitySummaryDataProvider class];
}
#endif

+ (Class)classForIntervalSamples
{
	return [DTXActivitySample class];
}

//- (NSArray<NSSortDescriptor *> *)sortDescriptors
//{
//	return @[[NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
//}

- (NSString *)displayName
{
	return NSLocalizedString(@"Activity", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Activity instrument captures system activity during the app's run time.", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"Activity"];
}

- (NSString *)helpTopicName
{
	return @"Activity";
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"Activity", @"")];
}

- (NSArray<NSString*>*)propertiesToFetch;
{
	return @[@"timestamp", @"endTimestamp"];
}

- (NSArray<NSString*>*)relationshipsToFetch
{
	return @[@"recording"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[NSColor.activityPlotControllerColor];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

- (NSDate*)endTimestampForSample:(DTXActivitySample*)sample
{
	return sample.endTimestamp ?: self.document.recordings.lastObject.endTimestamp;
}

- (NSColor*)colorForSample:(DTXActivitySample*)sample
{
	return sample.plotControllerColor;
}

- (NSString*)titleForSample:(DTXActivitySample*)sample
{
	return sample.category;
	
//	NSMutableString* rv = sample.name.mutableCopy;
//
//	if(sample.additionalInfoStart.length > 0)
//	{
//		[rv appendFormat:@" (%@)", sample.additionalInfoStart];
//	}
//
//	return rv;
}

@end
