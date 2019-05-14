//
//  DTXSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSamplePlotController-Private.h"
#import "DTXGraphHostingView.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import <LNInterpolation/LNInterpolation.h>
#import "DTXDetailController.h"
#import "NSAppearance+UIAdditions.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXScatterPlotView.h"
#import "DTXSeparatorView.h"

NSString* const DTXPlotControllerRequiredHeightDidChangeNotification = @"DTXPlotControllerRequiredHeightDidChangeNotification";

@interface DTXSamplePlotController () <CPTScatterPlotDelegate>

@end

@implementation DTXSamplePlotController
{
	CPTPlotRange* _pendingGlobalXPlotRange;
	CPTPlotRange* _pendingXPlotRange;
	
	NSStoryboard* _scene;
	
	NSArray<DTXPlotViewTextAnnotation*>* _textAnnotations;
	
	NSArray* _cachedPlotColors;
	
	NSMenu* _cachedGroupingMenu;
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
	[self _updateTextAnnotations:nil];
}

- (void)mouseMoved:(NSEvent *)event
{
	NSPoint pointInView = [self.wrapperView convertPoint:[event locationInWindow] fromView:nil];

	NSMutableArray<NSDictionary*>* dataPoints = [NSMutableArray new];

	for(__kindof DTXPlotView* plotView in self.plotViews)
	{
		if([plotView isKindOfClass:DTXScatterPlotView.class])
		{
			DTXScatterPlotView* scatterPlotView = plotView;

			double position;
			NSUInteger pointIdx = [scatterPlotView indexOfPointAtViewPosition:pointInView.x positionInPlot:&position valueAtPlotPosition:NULL];
			
			if(pointIdx == NSNotFound)
			{
				return;
			}
			
			double value = [scatterPlotView valueOfPointIndex:pointIdx];

			[dataPoints addObject:@{@"position": @(position), @"value": [self.class.formatterForDataPresentation stringForObjectValue:[self transformedValueForFormatter:@(value)]]}];
		}
	}

	if(dataPoints.count != self.plotViews.count)
	{
		return;
	}

	NSMutableArray* textAnnotations = [NSMutableArray new];

	[dataPoints enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull presentable, NSUInteger idx, BOOL * _Nonnull stop) {
		auto textAnnotation = [DTXPlotViewTextAnnotation new];
		textAnnotation.position = [presentable[@"position"] doubleValue];
		textAnnotation.text = presentable[@"value"];
		textAnnotation.priority = 1000;

		[self _updateAnnotationColors:@[textAnnotation] forPlotIndex:idx];

		[textAnnotations addObject:textAnnotation];
	}];

	[self _updateTextAnnotations:textAnnotations];
}

- (void)_updateTextAnnotations:(NSArray*)newTextAnnotations
{
	[_textAnnotations enumerateObjectsUsingBlock:^(DTXPlotViewTextAnnotation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXPlotView* plotView = self.plotViews[idx];
		NSMutableArray* newAnnotations = plotView.annotations.mutableCopy ?: [NSMutableArray new];
		[newAnnotations removeObject:obj];
		if(newTextAnnotations)
		{
			[newAnnotations addObject:newTextAnnotations[idx]];
		}
		
		plotView.annotations = newAnnotations;
	}];
	
	_textAnnotations = newTextAnnotations;
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
	
	NSUInteger plotViewIdx = 0;
	for (__kindof DTXPlotView* plotView in plotViews)
	{
		plotView.globalPlotRange = globalXRange;
		plotView.plotRange = xRange;
		plotView.delegate = self;
		
		plotView.plotIndex = plotViewIdx;
		plotViewIdx++;
		
		[self.plotStackView addArrangedSubview:plotView];
		
		if(self.includeSeparatorsInStackView && plotViewIdx < plotViews.count)
		{
			NSView* box = [DTXSeparatorView new];
			box.translatesAutoresizingMaskIntoConstraints = NO;
			[NSLayoutConstraint activateConstraints:@[
													  [box.heightAnchor constraintEqualToConstant:1],
													  ]];
			
			[self.plotStackView addArrangedSubview:box];
		}
	}
	plotViews.lastObject.insets = self.rangeInsets;
}

- (void)reloadPlotViews
{
	[self _removeHighlightNotifyingDelegate:YES];
	
	[self.plotStackView.arrangedSubviews.copy enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperviewWithoutNeedingDisplay];
	}];
	
	[self setupPlotViews];
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
	CGPoint pt;
	
	if(self.wrapperView.window.currentEvent.type == NSEventTypeKeyDown || self.wrapperView.window.currentEvent.type == NSEventTypeKeyUp)
	{
		pt = [self.plotViews.firstObject convertPointFromWindow:self.wrapperView.window.mouseLocationOutsideOfEventStream];
	}
	else
	{
		pt = CGPointMake(CGRectGetMidX(self.wrapperView.bounds), CGRectGetMidY(self.wrapperView.bounds));
	}
	
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
		[obj scalePlotRange:obj.plotRange.lengthDouble / obj.globalPlotRange.lengthDouble atPoint:NSZeroPoint];
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
	
	[self _highlightRange:range sampleIndex:NSNotFound isShadow:NO plotIndex:NSNotFound valueAtClickPosition:0 nofityDelegate:NO];
}

- (void)_highlightSample:(DTXSample*)sample sampleIndex:(NSUInteger)sampleIdx plotIndex:(NSUInteger)plotIndex positionInPlot:(double)position valueAtClickPosition:(double)value
{
	CPTPlotRange* range = [CPTPlotRange plotRangeWithLocation:@(position) length:@0];
	
	[self.delegate plotController:self didHighlightRange:range];
	
	[self _highlightRange:range sampleIndex:sampleIdx isShadow:NO plotIndex:plotIndex valueAtClickPosition:value nofityDelegate:NO];
}

- (void)shadowHighlightRange:(CPTPlotRange*)range
{
	[self _highlightRange:range sampleIndex:NSNotFound isShadow:YES plotIndex:NSNotFound valueAtClickPosition:0 nofityDelegate:NO];
}

- (void)_highlightRange:(CPTPlotRange*)range sampleIndex:(NSUInteger)sampleIdx isShadow:(BOOL)isShadow plotIndex:(NSUInteger)plotIndex valueAtClickPosition:(double)value nofityDelegate:(BOOL)notifyDelegate
{
	[self _removeHighlightNotifyingDelegate:NO];
	
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableArray* annotations = [NSMutableArray new];
		if(range.lengthDouble > 0)
		{
			DTXPlotViewRangeAnnotation* annotation1 = [DTXPlotViewRangeAnnotation new];
			annotation1.position = 0;
			annotation1.end = range.locationDouble;
			annotation1.opacity = 0.0;
			
			DTXPlotViewRangeAnnotation* annotation2 = [DTXPlotViewRangeAnnotation new];
			annotation2.position = range.locationDouble + range.lengthDouble;
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
			
			if([obj isKindOfClass:DTXScatterPlotView.class])
			{
				DTXScatterPlotView* scatterPlotView = (id)obj;
				annotation1.drawsValue = NO;
				if(isShadow == NO || self.isForTouchBar == YES)
				{
					if(idx == plotIndex)
					{
						annotation1.value = value;
					}
					else
					{
						annotation1.value = [scatterPlotView valueAtPlotPosition:range.locationDouble exact:YES];
					}
					
					double textValue;
					if(sampleIdx != NSNotFound)
					{
						textValue = [scatterPlotView valueOfPointIndex:sampleIdx];
					}
					else
					{
						textValue = annotation1.value;
					}
					
					DTXPlotViewTextAnnotation* text = [DTXPlotViewTextAnnotation new];
					text.text = [self.class.formatterForDataPresentation stringForObjectValue:[self transformedValueForFormatter:@(textValue)]];
					text.position = annotation1.position;
					[annotations addObject:text];
				}
			}
			
			[annotations addObject:annotation1];
		}
		
		if(_textAnnotations != nil)
		{
			[annotations addObject:_textAnnotations[idx]];
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
		if(_textAnnotations != nil)
		{
			obj.annotations = @[_textAnnotations[idx]];
		}
		else
		{
			obj.annotations = nil;
		}
	}];
	
	if(notify)
	{
		[self.delegate plotControllerDidRemoveHighlight:self];
	}
}

- (NSArray<NSColor*>*)_cachedPlotColors
{
	if(_cachedPlotColors == nil)
	{
		_cachedPlotColors = self.plotColors;
	}
	
	return _cachedPlotColors;
}

- (NSColor*)_plotColorForIdx:(NSUInteger)idx
{
	if(idx >= self._cachedPlotColors.count)
	{
		return self._cachedPlotColors.lastObject;
	}
	
	return self._cachedPlotColors[idx];
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
				line.color =  [[self _plotColorForIdx:plotIdx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.3];
			}
			
			line.valueColor = [[self _plotColorForIdx:plotIdx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
		}
		else if([annotation isKindOfClass:DTXPlotViewTextAnnotation.class])
		{
			DTXPlotViewTextAnnotation* text = (id)annotation;
			
			if(self.wrapperView.effectiveAppearance.isDarkAppearance)
			{
				text.color = NSColor.whiteColor;
			}
			else
			{
				text.color =  [[self _plotColorForIdx:plotIdx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.3];
			}
			text.valueColor = [[self _plotColorForIdx:plotIdx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
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

- (BOOL)includeSeparatorsInStackView
{
	return NO;
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
	return NSEdgeInsetsMake(0, 0, 1, 0);
}

- (id)transformedValueForFormatter:(id)value
{
	return value;
}

- (BOOL)canReceiveFocus
{
	return self.isForTouchBar == NO;
}

- (NSArray<NSString *> *)legendTitles
{
	return self.plotTitles;
}

- (NSArray<NSColor *> *)legendColors
{
	return self._cachedPlotColors;
}

- (NSMenu *)groupingSettingsMenu
{
	return nil;
}

- (BOOL)supportsQuickSettings
{
	return NO;
}

#pragma mark Internal Plots

- (void)plotViewDidChangePlotRange:(DTXPlotView *)plotView
{
	[self.plotStackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof DTXPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(plotView == obj)
		{
			return;
		}
		
		if([obj isKindOfClass:DTXPlotView.class] == NO)
		{
			return;
		}
		
		obj.plotRange = plotView.plotRange;
	}];
	
	[_delegate plotController:self didChangeToPlotRange:plotView.plotRange];
}

@end
