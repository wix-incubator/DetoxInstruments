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
#import "DTXRecording+UIExtensions.h"
#import "DTXStackedPlotGroup.h"
#import "DTXDetailController.h"
#import "NSAppearance+UIAdditions.h"
#import "DTXScatterPlotView.h"

@interface DTXSamplePlotController () <CPTScatterPlotDelegate, DTXScatterPlotViewDataSource>

@end

@implementation DTXSamplePlotController
{
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	
	NSStoryboard* _scene;
	
	NSArray* _plotViews;
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

	//TODO: Fix
	
//	if([self.graph.allPlots.firstObject isKindOfClass:[CPTScatterPlot class]])
//	{
//		NSPoint pointInView = [cgr locationInView:self.hostingView];
//
//		CPTNumberArray* pointInPlot = [self.graph.defaultPlotSpace plotPointForPlotAreaViewPoint:pointInView];
//
//		NSUInteger numberOfRecords = [self numberOfRecordsForPlot:self.plots.firstObject];
//		NSUInteger foundPointIndex = NSNotFound;
//		CGFloat foundPointDelta = 0;
//		for(NSUInteger idx = 0; idx < numberOfRecords; idx++)
//		{
//			NSNumber* xOfPointInPlot = [self numberForPlot:self.graph.allPlots.firstObject field:CPTScatterPlotFieldX recordIndex:idx];
//			if(xOfPointInPlot.doubleValue <= pointInPlot.firstObject.doubleValue)
//			{
//				foundPointIndex = idx;
//				foundPointDelta = pointInPlot.firstObject.doubleValue - xOfPointInPlot.doubleValue;
//			}
//			else
//			{
//				break;
//			}
//		}
//
//		if(foundPointIndex == NSNotFound)
//		{
//			return;
//		}
//
//		id sample = [self samplesForPlotIndex:((NSNumber*)self.plots.firstObject.identifier).unsignedIntegerValue][foundPointIndex];
//		id nextSample = foundPointIndex == numberOfRecords - 1 ? nil : [self samplesForPlotIndex:((NSNumber*)self.plots.firstObject.identifier).unsignedIntegerValue][foundPointIndex + 1];
//
//		if(self.parentPlotController)
//		{
//			DTXSamplePlotController* spc = (id)self.parentPlotController;
//			[spc _highlightSample:sample nextSample:nextSample plotSpaceOffset:foundPointDelta notifyDelegate:YES];
//		}
//		else
//		{
//			[self _highlightSample:sample nextSample:nextSample plotSpaceOffset:foundPointDelta notifyDelegate:YES];
//		}
//
//		[self.sampleClickDelegate plotController:(id)self.parentPlotController ?: self didClickOnSample:sample];
//	}

- (void)updateLayerHandler
{
	NSArray<NSColor*>* plotColors = self.plotColors;
	
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXScatterPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		BOOL isDark = self.wrapperView.effectiveAppearance.isDarkAppearance;
		BOOL isTouchBar = self.wrapperView.effectiveAppearance.isTouchBarAppearance;
		
		NSColor* lineColor;
		
		if([obj isKindOfClass:DTXScatterPlotView.class])
		{
			if(isDark || isTouchBar)
			{
				lineColor = NSColor.whiteColor;//[plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:1.0];
			}
			else
			{
				lineColor = [plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
			}
			
			obj.lineColor = lineColor;
			CGFloat maxWidth = isDark ? 1.5 : 1.0;
			obj.lineWidth = isTouchBar ? 0.0 : MAX(1.0, maxWidth / self.wrapperView.layer.contentsScale);
			
			NSColor* startColor;
			NSColor* endColor;
			
			if(isTouchBar)
			{
				startColor = self.plotColors[idx];
				//			startColor = [startColor colorWithAlphaComponent:0.4];
				endColor = startColor;
			}
			else if(isDark)
			{
				endColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.1];//[plotColors[idx] colorWithAlphaComponent:0.5];
				startColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];//[plotColors[idx] colorWithAlphaComponent:0.85];
				startColor = [startColor colorWithAlphaComponent:0.9];
				endColor = startColor;
			}
			else
			{
				startColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.5];
				endColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.7];
			}
			
			obj.fillColor1 = startColor;
			obj.fillColor2 = endColor;
		}
		else
		{
			[obj reloadData];
		}
		
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
	
	[self _highlightRange:range isShadow:NO nofityDelegate:NO];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range isShadow:YES nofityDelegate:NO];
}

- (void)_highlightRange:(CPTPlotRange*)range isShadow:(BOOL)isShadow nofityDelegate:(BOOL)notifyDelegate
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
			annotation1.color = NSColor.textColor;
			if(self.isForTouchBar == NO)
			{
				annotation1.opacity = 1.0;
			}
			
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
			if(self.wrapperView.effectiveAppearance.isDarkAppearance)
			{
				annotation.color = NSColor.whiteColor;
			}
			else
			{
				annotation.color = self.plotColors[plotIdx];
			}
		}
		else
		{
			annotation.color = NSColor.whiteColor;
		}
	}];
}

- (void)noteOfSampleInsertions:(NSArray<NSNumber*>*)insertions updates:(NSArray<NSNumber*>*)updates forPlotAtIndex:(NSUInteger)index
{
	DTXScatterPlotView* plotView = self.plotViews[index];
	
	for (NSNumber* obj in updates) {
		[plotView reloadPointAtIndex:obj.unsignedIntegerValue];
	}
	
	[plotView addNumberOfPoints:insertions.count];
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

- (CGFloat)plotHeightMultiplier;
{
	return self.isForTouchBar ? 1.0 : 1.15;
}

- (CGFloat)minimumValueForPlotHeight
{
	return 0.0;
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

- (NSArray<__kindof DTXPlotView*>*)plotViews
{
	if(_plotViews)
	{
		return _plotViews;
	}
	
	NSMutableArray* rv = [NSMutableArray new];
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXScatterPlotView* scatterPlotView = [[DTXScatterPlotView alloc] initWithFrame:CGRectZero];
		scatterPlotView.plotIndex = idx;
		
		scatterPlotView.minimumValueForPlotHeight = self.minimumValueForPlotHeight;
		scatterPlotView.stepped = self.isStepped;
		scatterPlotView.dataSource = self;
		
		if(self.sampleKeys.count == 2 && idx == 1)
		{
			scatterPlotView.flipped = YES;
		}
		
		scatterPlotView.plotHeightMultiplier = self.plotHeightMultiplier;
		
		[rv addObject:scatterPlotView];
	}];
	_plotViews = rv;
	
	return _plotViews;
}

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

#pragma mark DTXScatterPlotViewDataSource

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView *)plotView
{
	return [self samplesForPlotIndex:plotView.plotIndex].count;
}

- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView pointAtIndex:(NSUInteger)idx
{
	NSUInteger plotIdx = plotView.plotIndex;
	
	DTXScatterPlotViewPoint* rv = [DTXScatterPlotViewPoint new];
	rv.x = [[[self samplesForPlotIndex:plotIdx][idx] valueForKey:@"timestamp"] timeIntervalSinceReferenceDate] - [_document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.y = [[self transformedValueForFormatter:[[self samplesForPlotIndex:plotIdx][idx] valueForKey:self.sampleKeys[plotIdx]]] doubleValue];
	
	return rv;
}

@end
