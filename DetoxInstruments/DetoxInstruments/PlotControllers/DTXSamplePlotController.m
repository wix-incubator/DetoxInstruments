//
//  DTXSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSamplePlotController-Private.h"
#import "DTXGraphHostingView.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXLineLayer.h"
#import <LNInterpolation/LNInterpolation.h>
#import "DTXStackedPlotGroup.h"
#import "DTXDetailController.h"
#import "NSAppearance+UIAdditions.h"
#import "DTXRecording+UIExtensions.h"

@interface DTXSamplePlotController () <CPTScatterPlotDelegate>

@end

@implementation DTXSamplePlotController
{
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	
	NSStoryboard* _scene;
}

@synthesize delegate = _delegate;
@synthesize document = _document;
@synthesize sampleClickDelegate = _sampleClickDelegate;
@synthesize parentPlotController = _parentPlotController;
@dynamic helpTopicName;

+ (Class)graphHostingViewClass
{
	return [DTXGraphHostingView class];
}

+ (Class)UIDataProviderClass
{
	return nil;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar
{
	self = [super initForTouchBar:isForTouchBar];

	if(self)
	{
		_document = document;
		_scene = [NSStoryboard storyboardWithName:@"Profiler" bundle:nil];
		
		[self plotViews];
	}
	
	return self;
}

- (NSArray<DTXDetailController*>*)dataProviderControllers
{
	DTXDetailController* detailController = [_scene instantiateControllerWithIdentifier:@"DTXOutlineDetailController"];
	detailController.detailDataProvider = [[self.class.UIDataProviderClass alloc] initWithDocument:_document plotController:self];
	
	return @[detailController];
}

- (void)mouseEntered:(NSEvent *)event
{
	
}

- (void)mouseExited:(NSEvent *)event
{
	[self.hostingView removeAllToolTips];
}

- (void)mouseMoved:(NSEvent *)event
{
	//TODO: Fix
	
//	CGPoint pointInView = [self.hostingView convertPoint:[event locationInWindow] fromView:nil];
//
//	NSMutableArray<NSDictionary<NSString*, NSString*>*>* dataPoints = [NSMutableArray new];
//
//	[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//		NSUInteger numberOfRecords = [self numberOfRecordsForPlot:obj];
//		NSUInteger foundPointIndex = NSNotFound;
//		CGFloat foundPointDelta = 0;
//		CGFloat foundPointX = 0;
//		for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
//		{
//			CGPoint pointOfPoint = [obj plotAreaPointOfVisiblePointAtIndex:idx];
//			if(pointOfPoint.x <= pointInView.x)
//			{
//				foundPointIndex = idx;
//				foundPointDelta = pointInView.x - pointOfPoint.x;
//				foundPointX = pointOfPoint.x;
//			}
//			else
//			{
//				break;
//			}
//		}
//
//		if(foundPointIndex != NSNotFound)
//		{
//			id y = [self numberForPlot:obj field:CPTScatterPlotFieldY recordIndex:foundPointIndex];
//			if(self.isStepped == NO && foundPointIndex < numberOfRecords - 1)
//			{
//				CGPoint pointOfNextPoint = [obj plotAreaPointOfVisiblePointAtIndex:foundPointIndex + 1];
//				id nextY = [self numberForPlot:obj field:CPTScatterPlotFieldY recordIndex:foundPointIndex + 1];
//
//				y = [y interpolateToValue:nextY progress:foundPointDelta / (pointOfNextPoint.x - foundPointX)];
//			}
//
//			[dataPoints addObject:@{@"title":self.plotTitles[idx], @"data": [self.class.formatterForDataPresentation stringForObjectValue:[self transformedValueForFormatter:y]]}];
//		}
//	}];
//
//	if(dataPoints.count == 0)
//	{
//		return;
//	}
//
//	[self.hostingView removeAllToolTips];
//	if(dataPoints.count == 1)
//	{
//		[self.hostingView setToolTip:dataPoints.firstObject[@"data"]];
//	}
//	else
//	{
//		NSMutableString* tooltip = [NSMutableString new];
//		[dataPoints enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//			[tooltip appendString:[NSString stringWithFormat:@"%@: %@\n", obj[@"title"], obj[@"data"]]];
//		}];
//
//		[self.hostingView setToolTip:[tooltip stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
//	}
}

- (void)updateLayerHandler
{
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _updateAnnotationColors:obj.annotations forPlotIndex:idx];
		obj.annotations = obj.annotations;
	}];
}

- (BOOL)usesInternalPlots
{
	return YES;
}

- (void)setupPlotViews
{
	NSArray<__kindof DTXPlotView*>* plotViews = self.plotViews;
	
	CPTPlotRange *globalXRange;
	if(_pendingGlobalXPlotRange)
	{
		globalXRange = _pendingGlobalXPlotRange;
		_pendingGlobalXPlotRange = nil;
	}
	else
	{
		globalXRange = [CPTPlotRange plotRangeWithLocation:@0 length:@([_document.lastRecording.defactoEndTimestamp timeIntervalSinceReferenceDate] - [_document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate])];
	}
	
	CPTPlotRange* xRange = globalXRange;
	if(_pendingXPlotRange)
	{
		xRange = _pendingXPlotRange;
		_pendingXPlotRange = nil;
	}
	
	for (__kindof DTXPlotView* plotView in plotViews) {
		plotView.globalPlotRange = globalXRange;
		plotView.plotRange = xRange;
		plotView.insets = self.rangeInsets;
		plotView.delegate = self;
		
		[self.plotStackView addArrangedSubview:plotView];
	}
}

- (void)didFinishViewSetup
{
	[super didFinishViewSetup];
	
	[self prepareSamples];
	
	NSTrackingArea* tracker = [[NSTrackingArea alloc] initWithRect:self.wrapperView.bounds options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved owner:self userInfo:nil];
	[self.wrapperView addTrackingArea:tracker];
	
	__weak auto weakSelf = self;
	self.wrapperView.updateLayerHandler = ^ (NSView* view) {
		[weakSelf updateLayerHandler];
		
		[weakSelf.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[obj reloadData];
		}];
	};
}

- (void)setGlobalPlotRange:(CPTPlotRange*)globalPlotRange
{
	if(self.graph != nil)
	{
		[(CPTXYPlotSpace *)self.graph.defaultPlotSpace setGlobalXRange:globalPlotRange];
	}
	else if(self.plotStackView)
	{
		for (DTXPlotView* plotView in self.plotViews) {
			plotView.globalPlotRange = globalPlotRange;
		}
	}
	else
	{
		_pendingGlobalXPlotRange = globalPlotRange;
	}
}

- (void)setPlotRange:(CPTPlotRange *)plotRange
{
	if(self.graph != nil)
	{
		[(CPTXYPlotSpace *)self.graph.defaultPlotSpace setXRange:plotRange];
	}
	else if(self.plotStackView)
	{
		for (DTXPlotView* plotView in self.plotViews) {
			plotView.plotRange = plotRange;
		}
	}
	else
	{
		_pendingXPlotRange = plotRange;
	}
}

- (void)_zoomToScale:(CGFloat)scale
{
	CGPoint pt = CGPointMake(CGRectGetMidX(self.wrapperView.bounds), CGRectGetMidY(self.wrapperView.bounds));
	
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj scalePlotRange:scale atPoint:pt];
	}];
}

- (void)zoomIn
{
	[self _zoomToScale:2.0];
}

- (void)zoomOut
{
	[self _zoomToScale:0.5];
}

- (void)zoomToFitAllData
{
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.plotRange = obj.globalPlotRange;
	}];
}

- (CPTPlotRange*)plotRangeForSample:(DTXSample*) sample
{
	return [CPTPlotRange plotRangeWithLocation:@(sample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.defactoStartTimestamp.timeIntervalSinceReferenceDate) length:@0];
}

- (void)highlightSample:(DTXSample*)sample
{
	CPTPlotRange* range = [self plotRangeForSample:sample];
	
	[self.delegate plotController:self didHighlightRange:range];
	
	[self _highlightRange:range isShadow:NO valueAtClickPosition:0 nofityDelegate:NO];
}

- (void)_highlightSample:(DTXSample*)sample positionInPlot:(double)position valueAtClickPosition:(double)value
{
	CPTPlotRange* range = [CPTPlotRange plotRangeWithLocation:@(position) length:@0];
	
	[self.delegate plotController:self didHighlightRange:range];
	
	[self _highlightRange:range isShadow:NO valueAtClickPosition:value nofityDelegate:NO];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range isShadow:YES valueAtClickPosition:0 nofityDelegate:NO];
}

- (void)_highlightRange:(CPTPlotRange*)range isShadow:(BOOL)isShadow valueAtClickPosition:(double)value nofityDelegate:(BOOL)notifyDelegate
{
	[self _removeHighlightNotifyingDelegate:NO];
	
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableArray* annotations = [NSMutableArray new];
		if(range.lengthDouble > 0)
		{
			DTXPlotViewRangeAnnotation* annotation1 = [DTXPlotViewRangeAnnotation new];
			annotation1.start = 0;
			annotation1.end = range.locationDouble;
			annotation1.opacity = 0.0;
			
			DTXPlotViewRangeAnnotation* annotation2 = [DTXPlotViewRangeAnnotation new];
			annotation2.start = range.locationDouble + range.lengthDouble;
			annotation2.end = DBL_MAX;
			annotation2.opacity = 0.0;
			
			[annotations addObject:annotation1];
			[annotations addObject:annotation2];
			
			DTXPlotViewLineAnnotation* annotation3 = [DTXPlotViewLineAnnotation new];
			annotation3.position = range.locationDouble;
			if(self.isForTouchBar == NO)
			{
				annotation3.opacity = 0.4;
			}
			
			DTXPlotViewLineAnnotation* annotation4 = [DTXPlotViewLineAnnotation new];
			annotation4.position = range.locationDouble + range.lengthDouble;
			if(self.isForTouchBar == NO)
			{
				annotation4.opacity = 0.4;
			}
			
			[annotations addObject:annotation3];
			[annotations addObject:annotation4];
		}
		else
		{
			DTXPlotViewLineAnnotation* annotation1 = [DTXPlotViewLineAnnotation new];
			annotation1.position = range.locationDouble;
			if(self.isForTouchBar == NO)
			{
				annotation1.opacity = self.wrapperView.effectiveAppearance.isDarkAppearance ? 1.0 : isShadow ? 0.4 : 1.0;
			}
			
			annotation1.drawsValue = isShadow == NO;
			annotation1.value = value;
			
			[annotations addObject:annotation1];
		}
		
		[self _updateAnnotationColors:annotations forPlotIndex:idx];
		
		obj.annotations = annotations;
	}];
	
	if(notifyDelegate)
	{
		[self.delegate plotController:self didHighlightRange:range];
	}
}

- (void)removeHighlight
{
	[self _removeHighlightNotifyingDelegate:YES];
}

- (void)_removeHighlightNotifyingDelegate:(BOOL)notify;
{
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.annotations = nil;
	}];
	
	if(notify)
	{
		[self.delegate plotControllerDidRemoveHighlight:self];
	}
}

- (void)_updateAnnotationColors:(NSArray<DTXPlotViewAnnotation*>*)annotations forPlotIndex:(NSUInteger)plotIdx
{
	[annotations enumerateObjectsUsingBlock:^(DTXPlotViewAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
		if([annotation isKindOfClass:DTXPlotViewLineAnnotation.class])
		{
			DTXPlotViewLineAnnotation* line = (id)annotation;
			
			if(self.wrapperView.effectiveAppearance.isDarkAppearance)
			{
				line.color = NSColor.whiteColor;
			}
			else
			{
				line.color =  [self.plotColors[plotIdx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.3];
			}
			
			line.valueColor = [self.plotColors[plotIdx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
		}
		else
		{
			annotation.color = NSColor.whiteColor;
		}
	}];
}

- (void)noteOfSampleInsertions:(NSArray<NSNumber*>*)insertions updates:(NSArray<NSNumber*>*)updates forPlotAtIndex:(NSUInteger)index
{
}

- (NSString *)displayName
{
	return @"";
}

- (NSString *)toolTip
{
	return nil;
}

- (NSImage*)displayIcon
{
	return nil;
}

- (NSImage *)smallDisplayIcon
{
	NSImage* image = [NSImage imageNamed:[NSString stringWithFormat:@"%@_small", self.displayIcon.name]];
	image.size = NSMakeSize(16, 16);
	
	return image;
}

- (NSImage *)secondaryIcon
{
    return nil;
}

- (NSFont *)titleFont
{
	return [NSFont systemFontOfSize:NSFont.systemFontSize];
}

- (CGFloat)requiredHeight
{
	return 80;
}

- (void)prepareSamples
{
	
}

- (NSArray<DTXPlotView *> *)plotViews
{
	return nil;
}

- (NSArray*)samplesForPlotIndex:(NSUInteger)index
{
	return @[];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[];
}

- (NSArray<NSString*>*)propertiesToFetch;
{
	return @[@"timestamp"];
}

- (NSArray<NSString*>*)relationshipsToFetch
{
	return nil;
}

- (NSArray<NSColor*>*)plotColors
{
	return @[];
}

- (NSArray<NSString *>*)plotTitles
{
	return @[];
}

- (NSArray<CPTPlotSpaceAnnotation*>*)graphAnnotationsForGraph:(CPTGraph*)graph
{
	return @[];
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_stringFormatter];
}

- (NSEdgeInsets)rangeInsets
{
	return NSEdgeInsetsZero;
}

- (id)transformedValueForFormatter:(id)value
{
	return value;
}

- (BOOL)isStepped
{
	return NO;
}

- (BOOL)canReceiveFocus
{
	return YES;
}

- (NSArray<NSString *> *)legendTitles
{
	return self.plotTitles;
}

- (NSArray<NSColor *> *)legendColors
{
	return self.plotColors;
}

#pragma mark Internal Plots

- (void)plotViewDidChangePlotRange:(DTXPlotView *)plotView
{
	[self.plotStackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(plotView == obj)
		{
			return;
		}
		
		obj.plotRange = plotView.plotRange;
	}];
	
	[_delegate plotController:self didChangeToPlotRange:plotView.plotRange];
}

@end
