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
#import "DTXSignpostSummaryDataProvider.h"
#import "DTXSignpostFlatDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXDetailController.h"
#import "DTXIntervalSamplePlotController-Private.h"

static NSDictionary* _tagToKeyPathMapping;

@implementation DTXEventsPlotController
{
	NSUInteger _sectionTag;
	NSString* _sectionKeyPath;
}

+ (void)load
{
	_tagToKeyPathMapping = @{@1: @"category", @2: @"startThreadNumber"};
}

- (instancetype)initWithDocument:(DTXRecordingDocument *)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super _initWithDocument:document isForTouchBar:isForTouchBar sectionConfigurator:^{
		_sectionTag = [[self.document objectForPreferenceKey:__DTXPlotControllerCacheKeyForObject(self)] unsignedIntegerValue];
		_sectionKeyPath = _tagToKeyPathMapping[@(_sectionTag)];
	}];
	
	return self;
}

- (NSArray<DTXDetailController *> *)dataProviderControllers
{
	NSMutableArray* rv = [NSMutableArray new];
	
	DTXDetailController* flatController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	flatController.detailDataProvider = [[DTXSignpostFlatDataProvider alloc] initWithDocument:self.document plotController:self];
	
	[rv addObject:flatController];
	
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		DTXDetailController* detailController = [self.scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
		detailController.detailDataProvider = [[DTXSignpostSummaryDataProvider alloc] initWithDocument:self.document plotController:self];
		
		[rv insertObject:detailController atIndex:0];
	}
	
	return rv;
}

+ (Class)UIDataProviderClass
{
	return [DTXSignpostSummaryDataProvider class];
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

- (NSString *)sectionKeyPath
{
	return _sectionKeyPath;
}

- (NSMenu *)groupingSettingsMenu
{
	NSMenu* menu = [NSMenu new];
	
	NSMenuItem* noGrouping = [NSMenuItem new];
	noGrouping.title = @"None";
	noGrouping.target = self;
	noGrouping.action = @selector(reloadSections:);
	noGrouping.tag = 0;
	noGrouping.state = _sectionTag == noGrouping.tag;
	[menu addItem:noGrouping];
	
	NSMenuItem* sectionGrouping = [NSMenuItem new];
	sectionGrouping.title = @"Category";
	sectionGrouping.target = self;
	sectionGrouping.action = @selector(reloadSections:);
	sectionGrouping.tag = 1;
	sectionGrouping.state = _sectionTag == sectionGrouping.tag;
	[menu addItem:sectionGrouping];
	
	NSMenuItem* threadGrouping = [NSMenuItem new];
	threadGrouping.title = @"Starting Thread";
	threadGrouping.target = self;
	threadGrouping.action = @selector(reloadSections:);
	threadGrouping.tag = 2;
	threadGrouping.state = _sectionTag == threadGrouping.tag;
	[menu addItem:threadGrouping];
	
	return menu;
}

- (BOOL)supportsQuickSettings
{
	return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSString* sectionKeyPath = _tagToKeyPathMapping[@(menuItem.tag)];
	
	menuItem.state = sectionKeyPath == _sectionKeyPath || [sectionKeyPath isEqualToString:_sectionKeyPath] ? NSControlStateValueOn : NSControlStateValueOff;
	
	return YES;
}

static NSString* __DTXPlotControllerCacheKeyForObject(id<NSObject> object)
{
	return [NSString stringWithFormat:@"SectionTag_%@", NSStringFromClass(object.class)];
}


- (IBAction)reloadSections:(NSMenuItem*)sender
{
	NSUInteger sectionTag = sender.tag;
	
	if(sectionTag != _sectionTag)
	{
		_sectionTag = sectionTag;
		_sectionKeyPath = _tagToKeyPathMapping[@(sender.tag)];
		[self.document setObject:@(_sectionTag) forPreferenceKey:__DTXPlotControllerCacheKeyForObject(self)];
		[self invalidateSections];
	}
}

@end
