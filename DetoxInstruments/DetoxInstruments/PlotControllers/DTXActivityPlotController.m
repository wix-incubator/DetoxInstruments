//
//  DTXActivityPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXActivityPlotController.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#if ! PROFILER_PREVIEW_EXTENSION
#import "DTXActivityFlatDataProvider.h"
#import "DTXActivitySummaryDataProvider.h"
#import "DTXDetailController.h"
#import "DTXStringPickerViewController.h"
#endif
#import "DTXActivitySample+UIExtensions.h"
#import "DTXIntervalSamplePlotController-Private.h"

NSString* const DTXActivityPlotEnabledCategoriesDidChange = @"DTXActivityPlotEnabledCategoriesDidChange";

#if ! PROFILER_PREVIEW_EXTENSION
@interface DTXActivityPlotController () <DTXStringPickerViewControllerDelegate> @end
#endif

@implementation DTXActivityPlotController
{
#if ! PROFILER_PREVIEW_EXTENSION
	DTXDetailController* _flatDetailController;
	DTXActivityFlatDataProvider* _flatDataProvider;
	
	DTXDetailController* _summaryDetailController;
	DTXActivitySummaryDataProvider* _summaryDataProvider;
	
	NSTimer* _delayedTimer;
#endif
}

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super _initWithDocument:document isForTouchBar:isForTouchBar sectionConfigurator:nil];
	
	return self;
}

#if ! PROFILER_PREVIEW_EXTENSION
- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	NSMutableArray* rv = [NSMutableArray new];

	if(_flatDetailController == nil)
	{
		_flatDetailController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
		_flatDataProvider = [[DTXActivityFlatDataProvider alloc] initWithDocument:self.document plotController:self];
		_flatDetailController.detailDataProvider = _flatDataProvider;
	}
	
	[rv addObject:_flatDetailController];
	
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		if(_summaryDetailController == nil)
		{
			_summaryDetailController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
			_summaryDataProvider = [[DTXActivitySummaryDataProvider alloc] initWithDocument:self.document plotController:self];
			_summaryDetailController.detailDataProvider = _summaryDataProvider;
		}
		
		[rv insertObject:_summaryDetailController atIndex:0];
	}
	
	NSSet* cats = self.enabledCategories;
	_flatDataProvider.enabledCategories = cats;
	_summaryDataProvider.enabledCategories = cats;
	
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

#if ! PROFILER_PREVIEW_EXTENSION
- (NSPredicate *)predicateForPerformanceSamples
{
	NSSet* enabled = self.enabledCategories;
	
	if(enabled != nil)
	{
		return [NSPredicate predicateWithFormat:@"category IN %@", enabled];
	}
	else
	{
		return [super predicateForPerformanceSamples];
	}
}
#endif

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
//	return sample.category;
	return [NSString stringWithFormat:@"%@: %@", sample.category, sample.name];
}

- (NSMenu *)quickSettingsMenu
{
	return nil;
}

- (void)showQuickSettings:(NSButton*)sender
{
#if ! PROFILER_PREVIEW_EXTENSION
	DTXStringPickerViewController* picker = [[NSStoryboard storyboardWithName:@"Profiler" bundle:[NSBundle bundleForClass:self.class]] instantiateControllerWithIdentifier:@"DTXStringPickerViewController"];
	picker.delegate = self;
	
	NSFetchRequest* fr = [DTXActivitySample fetchRequest];
	fr.resultType = NSDictionaryResultType;
	fr.propertiesToFetch = @[@"category"];
	fr.propertiesToGroupBy = @[@"category"];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES]];
	
	NSArray* categories = [[self.document.viewContext executeFetchRequest:fr error:NULL] valueForKey:@"category"];
	
	NSSet* enabled = self.enabledCategories ?: [NSSet setWithArray:categories];
	
	picker.strings = [NSOrderedSet orderedSetWithArray:categories];
	picker.enabledStrings = enabled;
	
	NSPopover* popover = [NSPopover new];
	popover.behavior = NSPopoverBehaviorTransient;
	popover.contentViewController = picker;
	
	[popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSRectEdgeMaxX];
#endif
}

- (BOOL)supportsQuickSettings
{
	return YES;
}

#pragma mark DTXStringPickerViewControllerDelegate

#if ! PROFILER_PREVIEW_EXTENSION

- (NSSet<NSString*>*)enabledCategories
{
	return [self.document objectForPreferenceKey:@"ActivityEnabledCategories"];
}

- (void)stringPickerDidChangeEnabledStrings:(DTXStringPickerViewController*)pvc
{
	NSSet* categories = pvc.enabledStrings;
	if([self.enabledCategories isEqualToSet:categories])
	{
		return;
	}
	
	[_delayedTimer invalidate];
	_delayedTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[pvc setShowsLoadingIndicator:YES];
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self.document setObject:categories forPreferenceKey:@"ActivityEnabledCategories"];
			[self invalidateSections];
			
			_flatDataProvider.enabledCategories = categories;
			_summaryDataProvider.enabledCategories = categories;
			[pvc setShowsLoadingIndicator:NO];
		});
	}];
}

#endif

@end
