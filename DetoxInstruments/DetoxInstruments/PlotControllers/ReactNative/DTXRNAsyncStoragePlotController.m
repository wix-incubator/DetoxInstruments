//
//  DTXRNAsyncStoragePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/22/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNAsyncStoragePlotController.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXRNAsyncStorageFetchesDataProvider.h"
#import "DTXRNAsyncStorageSavesDataProvider.h"
#import "DTXDetailController.h"
#endif
#import "DTXSamplePlotController-Private.h"
#import "DTXLinePlotView.h"
#import "NSAppearance+UIAdditions.h"
#import "NSColor+UIAdditions.h"
#import "DTXRecording+Additions.h"
#import "NSFormatter+PlotFormatters.h"
@import ObjectiveC;

@implementation DTXRNAsyncStoragePlotController

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	if(self)
	{
		self.plotStackView.shouldSynchronizePlotHeights = NO;
	}
	return self;
}

#if ! PROFILER_PREVIEW_EXTENSION
- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	DTXDetailController* detailController1 = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	detailController1.detailDataProvider = [[DTXRNAsyncStorageFetchesDataProvider alloc] initWithDocument:self.document plotController:self];
	
	NSMutableArray* rv = [NSMutableArray new];
	
	[rv addObject:detailController1];
	
	DTXDetailController* detailController2 = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	detailController2.detailDataProvider = [[DTXRNAsyncStorageSavesDataProvider alloc] initWithDocument:self.document plotController:self];
	
	[rv addObject:detailController2];
	
	return rv;
}

#endif

+ (Class)classForPlotViews
{
	return DTXLinePlotView.class;
}

- (void)updateLayerHandler
{
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXLinePlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSColor* plotColorForIdx = [self _plotColorForIdx:idx];
		
		NSColor* lineColor = [plotColorForIdx deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
		
		obj.lineColor = lineColor;
		obj.lineWidth = 1.5;
	}];
	
	struct objc_super super = {.receiver = self, .super_class = self.superclass.superclass};
	void (*super_class)(struct objc_super*, SEL) = (void*)objc_msgSendSuper;
	super_class(&super, _cmd);
}

+ (Class)classForPerformanceSamples
{
	return [DTXReactNativeAsyncStorageSample class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Async Storage", @"");
}

- (NSString *)toolTip
{
	return NSLocalizedString(@"The Async Storage instrument captures information about React Native async storage fetches and saves in the profiled app.", @"");
}

- (NSString *)helpTopicName
{
	return @"AsyncStorage";
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"RNAsyncStorage"];
}

- (NSImage *)secondaryIcon
{
	return [NSImage imageNamed:@"react"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"fetchDuration", @"saveDuration"];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor.systemTealColor colorWithAlphaComponent:1.0], [NSColor.systemBrownColor colorWithAlphaComponent:1.0]];
}

- (NSArray<NSString*>*)plotTitles
{
	return @[NSLocalizedString(@"Fetch Duration", @""), NSLocalizedString(@"Save Duration", @"")];
}

- (NSArray<NSString*>*)legendTitles
{
	return @[NSLocalizedString(@"Fetch Duration", @""), NSLocalizedString(@"Save Duration", @"")];
}

- (NSString*)annotationStringValueForTransformedValue:(id)value
{
	if([value doubleValue] == 0.0)
	{
		return nil;
	}
	
	return [self.class.formatterForDataPresentation stringForObjectValue:value];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_durationFormatter];
}

- (BOOL)includeSeparatorsInStackView
{
	return YES;
}

@end
