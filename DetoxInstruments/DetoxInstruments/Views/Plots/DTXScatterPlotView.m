//
//  DTXScatterPlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/30/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXScatterPlotView-Private.h"
#import "NSAppearance+UIAdditions.h"

@interface DTXScatterPlotView ()

@property (nonatomic, strong) NSMutableArray<DTXScatterPlotViewPoint*>* _points;
@property (nonatomic, strong) NSMutableArray<DTXScatterPlotViewPoint*>* _additionalPoints;

@end

static DTX_ALWAYS_INLINE double __DTXValueAtIndex(NSArray<DTXScatterPlotViewPoint*>* points, DTXScatterPlotViewPoint* point, double test, NSUInteger idx, double graphHeightViewRatio, BOOL hideLower)
{
	double rv;
	
	if(test == 1)
	{
		rv = graphHeightViewRatio * point.y;
	}
	else
	{
		double value = 0;
		for(NSUInteger innerIdx = idx; innerIdx < idx + test && innerIdx + 1 < points.count; innerIdx++)
		{
			DTXScatterPlotViewPoint* point = [points objectAtIndex:innerIdx];
			value = MAX(value, (graphHeightViewRatio * point.y));
		}
		rv = value;
	}
	
	if(rv < 0.5 && hideLower)
	{
		rv = -1.0;
	}
	
	return rv;
}

static DTX_ALWAYS_INLINE void __DTXStartPaths(CGMutablePathRef* closedPath, CGMutablePathRef* openPath, NSEdgeInsets insets, BOOL isFlipped, CGFloat position, CGFloat value, BOOL isStepped)
{
	*closedPath = CGPathCreateMutable();
	*openPath = CGPathCreateMutable();
	CGPathMoveToPoint(*closedPath, NULL, position, __DTXBottomInset(insets, isFlipped));
	CGPathAddLineToPoint(*closedPath, NULL, position, value);
	CGPathMoveToPoint(*openPath, NULL, position, value);
}

static DTX_ALWAYS_INLINE void __DTXFlushPaths(DTXScatterPlotView* self, NSColor* fillColor1, NSColor* fillColor2, NSColor* lineColor, CGContextRef ctx, CGMutablePathRef closedPath, CGMutablePathRef openPath, CGFloat position, NSUInteger drawingType, BOOL dashedLine, double fillStart, double fillLimit)
{
	CGPathAddLineToPoint(closedPath, NULL, position, __DTXBottomInset(self.insets, self.isFlipped));
	
	CGContextAddPath(ctx, closedPath);
	CGContextClip(ctx);
	
	if(drawingType == 1)
	{
		
		fillColor1 = [NSColor.systemGrayColor colorWithAlphaComponent:fillColor1.alphaComponent * 0.2];
		fillColor2 = [NSColor.systemGrayColor colorWithAlphaComponent:fillColor2.alphaComponent * 0.2];
	}
	
	if([fillColor1 isEqualTo:fillColor2] == NO)
	{
		CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)@[(__bridge id)fillColor1.CGColor, (__bridge id)fillColor2.CGColor], NULL);
		CGContextDrawLinearGradient(ctx, gradient, CGPointMake(CGRectGetMidX(self.bounds), fillStart), CGPointMake(CGRectGetMidX(self.bounds), fillLimit), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
		CGGradientRelease(gradient);
	}
	else
	{
		CGContextSetFillColorWithColor(ctx, fillColor1.CGColor);
		CGContextFillRect(ctx, self.bounds);
	}

	CGContextResetClip(ctx);
	NSRect selfBounds = self.bounds;
	NSEdgeInsets insets = self.insets;
	BOOL isFlipped = self.isFlipped;
	CGContextClipToRect(ctx, NSMakeRect(self.bounds.origin.x, self.bounds.origin.y + __DTXBottomInset(insets, isFlipped), selfBounds.size.width, selfBounds.size.height - insets.bottom - insets.top));
	
	if(drawingType == 1)
	{
		lineColor = [NSColor.systemGrayColor colorWithAlphaComponent:lineColor.alphaComponent * 0.5];
	}
	
	if(self.lineWidth > 0.0 && self.lineColor.alphaComponent > 0.0)
	{
		if(dashedLine)
		{
			CGContextSetLineDash(ctx, 0.0, (CGFloat[]){4.0, 4.0}, 2);
		}
		CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
		CGContextSetLineWidth(ctx, self.lineWidth);
		CGContextAddPath(ctx, openPath);
		CGContextStrokePath(ctx);
	}
	
	CGPathRelease(closedPath);
	CGPathRelease(openPath);
}

static DTX_ALWAYS_INLINE void __DTXDrawPoints(DTXScatterPlotView* self, NSArray<DTXScatterPlotViewPoint*>* points, NSColor* fillColor1, NSColor* fillColor2, double fillStartValue, double fillLimitValue, NSColor* lineColor, BOOL dashedLine, CGContextRef ctx)
{
	DTXPlotRange* plotRange = self.plotRange;
	double maxHeight = (self.heightSynchronizer ? self.heightSynchronizer.maximumPlotHeight : self.maxHeight);
	NSEdgeInsets insets = self.insets;
	BOOL isStepped = self.isStepped;
	BOOL isFlipped = self.isFlipped;
	
	CGRect selfBounds = self.bounds;
	
	if(self._points.count == 0)
	{
		return;
	}
	
	if(CGRectEqualToRect(selfBounds, CGRectZero))
	{
		return;
	}
	
	CGFloat graphViewRatio = selfBounds.size.width / plotRange.length;
	CGFloat graphHeightViewRatio = (selfBounds.size.height - insets.top - insets.bottom) / (maxHeight * self.plotHeightMultiplier);
	CGFloat offset = - graphViewRatio * plotRange.position;
	
	NSUInteger firstPointIdx = 0;
	NSUInteger lastPointIdx = points.count - 1;
	
	double fillStart = CGRectGetMinY(self.bounds);
	if(fillStartValue >= 0)
	{
		fillStart = fillStartValue * graphHeightViewRatio;
	}
	
	double fillLimit = CGRectGetMaxY(self.bounds);
	if(fillLimitValue >= 0)
	{
		fillLimit = fillLimitValue * graphHeightViewRatio;
	}
	
	for(NSUInteger idx = 0; idx < points.count; idx++)
	{
		DTXScatterPlotViewPoint* point = [points objectAtIndex:idx];
		CGFloat position = offset + graphViewRatio * point.x;
		if(position > 0)
		{
			break;
		}
		
		firstPointIdx = idx;
	}
	
	for(NSUInteger idx = points.count - 1; idx > firstPointIdx; idx--)
	{
		DTXScatterPlotViewPoint* point = [points objectAtIndex:idx];
		CGFloat position = offset + graphViewRatio * point.x;
		if(position < selfBounds.size.width)
		{
			break;
		}
		
		lastPointIdx = idx;
	}
	
	NSMutableArray<_DTXDrawingZone*>* zones = [NSMutableArray new];
	__DTXFillZones(self, zones);
	
	DTXScatterPlotViewPoint* point = points[firstPointIdx];
	double oldPosition = offset + graphViewRatio * point.x;
	double oldValue = __DTXValueAtIndex(points, point, 1, firstPointIdx, graphHeightViewRatio, dashedLine) + __DTXBottomInset(insets, isFlipped) + __DTXBottomInset(insets, isFlipped);
	
	NSUInteger currentZoneIdx = 0;
	for(NSUInteger idx = 0; idx < zones.count; idx++)
	{
		_DTXDrawingZone* zone = zones[idx];
		if(zone.start <= oldPosition)
		{
			currentZoneIdx = idx;
		}
	}
	
	CGMutablePathRef closedPath;
	CGMutablePathRef openPath;
	__DTXStartPaths(&closedPath, &openPath, insets, isFlipped, oldPosition, oldValue, isStepped);
	
	NSUInteger test = ceil(MIN(80, MAX(1.0, (lastPointIdx - firstPointIdx) / (selfBounds.size.width))));
	
	for(NSUInteger idx = firstPointIdx + 1; idx <= lastPointIdx; idx += 1)
	{
		point = [points objectAtIndex:idx];
		double nextPosition = offset + graphViewRatio * point.x;
		double nextValue = __DTXValueAtIndex(points, point, test, idx, graphHeightViewRatio, dashedLine) + __DTXBottomInset(insets, isFlipped);
			
		while(currentZoneIdx < zones.count - 1 && nextPosition > zones[currentZoneIdx + 1].start)
		{
			double nextZoneStart = zones[currentZoneIdx + 1].start;
			
			double midPosition = nextZoneStart;
			
			if(isStepped)
			{
				CGPathAddLineToPoint(closedPath, NULL, midPosition, oldValue);
				CGPathAddLineToPoint(openPath, NULL, midPosition, oldValue);
				
				__DTXFlushPaths(self, self.fillColor1, self.fillColor2, self.lineColor, ctx, closedPath, openPath, midPosition, zones[currentZoneIdx].drawingType, dashedLine, fillStart, fillLimit);
				__DTXStartPaths(&closedPath, &openPath, insets, isFlipped, midPosition, oldValue, isStepped);
				
				CGPathAddLineToPoint(closedPath, NULL, nextPosition, oldValue);
				CGPathAddLineToPoint(openPath, NULL, nextPosition, oldValue);
			}
			else
			{
				double midValue = lerp(oldValue, nextValue, (midPosition - oldPosition) / (nextPosition - oldPosition));
				
				CGPathAddLineToPoint(closedPath, NULL, midPosition, midValue);
				CGPathAddLineToPoint(openPath, NULL, midPosition, midValue);
				
				__DTXFlushPaths(self, fillColor1, fillColor2, lineColor, ctx, closedPath, openPath, midPosition, zones[currentZoneIdx].drawingType, dashedLine, fillStart, fillLimit);
				__DTXStartPaths(&closedPath, &openPath, insets, isFlipped, midPosition, midValue, isStepped);
			}
			
			currentZoneIdx++;
		}
		
		if(isStepped)
		{
			CGPathAddLineToPoint(closedPath, NULL, nextPosition, oldValue);
			CGPathAddLineToPoint(openPath, NULL, nextPosition, oldValue);
		}
		
		CGPathAddLineToPoint(closedPath, NULL, nextPosition, nextValue);
		CGPathAddLineToPoint(openPath, NULL, nextPosition, nextValue);
		
		oldPosition = nextPosition;
		oldValue = nextValue;
	}
	
	__DTXFlushPaths(self, fillColor1, fillColor2, lineColor, ctx, closedPath, openPath, oldPosition, zones[currentZoneIdx].drawingType, dashedLine, fillStart, fillLimit);
}

@implementation DTXScatterPlotViewPoint

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> x: %@ y: %@", self.className, self, @(self.x), @(self.y)];
}

@end

@implementation DTXScatterPlotView

@dynamic dataSource, delegate;
@synthesize _points=_points;
@synthesize _additionalPoints=_additionalPoints;
@synthesize maxHeight=_maxHeight;

- (void)_commonInit
{
	[super _commonInit];
	
	self.wantsLayer = YES;
	self.layer.drawsAsynchronously = NO;
	self.additionalFillLimitValue = -1.0;
	self.additionalFillStartValue = -1.0;
	//For furure live resize support.
	//		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	//		self.layerContentsPlacement = NSViewLayerContentsPlacementLeft;
	_lineWidth = 1.0;
	self.insets = NSEdgeInsetsZero;
	self.plotHeightMultiplier = 1.0;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if(self.isDataLoaded == NO)
	{
		[self reloadData];
	}
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	__DTXDrawPoints(self, _points, self.fillColor1, self.fillColor2, -1.0, -1.0, self.lineColor, NO, ctx);
	if(_additionalPoints != nil)
	{
		__DTXDrawPoints(self, _additionalPoints, self.additionalFillColor1 ?: self.fillColor1, self.additionalFillColor2 ?: self.fillColor2, self.additionalFillStartValue, self.additionalFillLimitValue, self.additionalLineColor ?: NSColor.clearColor, YES, ctx);
	}
	[super drawRect:dirtyRect];
}

- (void)setLineWidth:(double)lineHeight
{
	_lineWidth = lineHeight;
	
	[self setNeedsDisplay:YES];
}

- (void)setStepped:(BOOL)stepped
{
	_stepped = stepped;
	
	[self setNeedsDisplay:YES];
}

- (void)setPlotHeightMultiplier:(double)plotHeightMultiplier
{
	_plotHeightMultiplier = plotHeightMultiplier;
	
	[self setNeedsDisplay:YES];
}

- (void)setMinimumValueForPlotHeight:(double)minimumValueForPlotHeight
{
	_minimumValueForPlotHeight = minimumValueForPlotHeight;
	
	[self setNeedsDisplay:YES];
}

- (void)_insertPoint:(DTXScatterPlotViewPoint*)point additionalPoint:(DTXScatterPlotViewPoint*)additionalPoint atIndex:(NSUInteger)idx
{
	_points[idx] = point;
	
	if(additionalPoint)
	{
		DTXScatterPlotViewPoint* actualAdditionalPoint = [DTXScatterPlotViewPoint new];
		actualAdditionalPoint.x = point.x;
		actualAdditionalPoint.y = additionalPoint.y;
		_additionalPoints[idx] = actualAdditionalPoint;
	}
	
	_maxHeight = MAX(0.01, MAX(_heightSynchronizer.maximumPlotHeight, MAX(_maxHeight, MAX(_minimumValueForPlotHeight, point.y))));
	_heightSynchronizer.maximumPlotHeight = _maxHeight;
}

- (void)setLineColor:(NSColor *)lineColor
{
	_lineColor = lineColor;
	
	[self setNeedsDisplay:YES];
}

- (void)setFillColor1:(NSColor *)fillColor1
{
	_fillColor1 = fillColor1;
	
	[self setNeedsDisplay:YES];
}

- (void)setFillColor2:(NSColor *)fillColor2
{
	_fillColor2 = fillColor2;
	
	[self setNeedsDisplay:YES];
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(NSViewNoIntrinsicMetric, NSViewNoIntrinsicMetric);
}

- (BOOL)hasAdditionalPoints
{
	return _additionalPoints != nil;
}

- (void)reloadData
{
	//	CFTimeInterval start = CACurrentMediaTime();
	
	@autoreleasepool
	{
		NSUInteger count = [self.dataSource numberOfSamplesInPlotView:self];
		
		_points = [[NSMutableArray alloc] initWithCapacity:count];
		
		BOOL hasAdditionalPoints = [self.dataSource hasAdditionalPointsForPlotView:self];
		if(hasAdditionalPoints)
		{
			_additionalPoints = [[NSMutableArray alloc] initWithCapacity:count];
		}
		else
		{
			_additionalPoints = nil;
		}
		
		for(NSUInteger idx = 0; idx < count; idx++)
		{
			DTXScatterPlotViewPoint* point = [self.dataSource plotView:self pointAtIndex:idx];
			NSParameterAssert(point != nil);
			
			DTXScatterPlotViewPoint* additionalPoint = nil;
			if(hasAdditionalPoints)
			{
				additionalPoint = [self.dataSource plotView:self additionalPointAtIndex:idx];
				NSParameterAssert(additionalPoint != nil);
			}
			
			[self _insertPoint:point additionalPoint:additionalPoint atIndex:idx];
		}
		
		[super reloadData];
	}
	
	[self setNeedsDisplay:YES];
	
	//	CFTimeInterval end = CACurrentMediaTime();
	//	NSLog(@"Took %@s to reload data", @(end - start));
}

- (void)reloadPointAtIndex:(NSUInteger)index
{
	//	CFTimeInterval start = CACurrentMediaTime();
	
	DTXScatterPlotViewPoint* newPoint = [self.dataSource plotView:self pointAtIndex:index];
	NSParameterAssert(newPoint != nil);
	
	DTXScatterPlotViewPoint* additionalPoint = nil;
	if([self.dataSource hasAdditionalPointsForPlotView:self])
	{
		additionalPoint = [self.dataSource plotView:self additionalPointAtIndex:index];
		NSParameterAssert(additionalPoint != nil);
	}
	
	[self _insertPoint:newPoint additionalPoint:additionalPoint atIndex:index];
	
	[self setNeedsDisplay:YES];
	
	//	CFTimeInterval end = CACurrentMediaTime();
	//	NSLog(@"Took %@s to reload sample", @(end - start));
}

- (void)addNumberOfPoints:(NSUInteger)numberOfPoints
{
	//	CFTimeInterval start = CACurrentMediaTime();
	
	BOOL hasAdditionalPoints = [self.dataSource hasAdditionalPointsForPlotView:self];
	
	NSUInteger count = _points.count + numberOfPoints;
	for(NSUInteger idx = _points.count; idx < count; idx++)
	{
		DTXScatterPlotViewPoint* point = [self.dataSource plotView:self pointAtIndex:idx];
		
		NSParameterAssert(point != nil);
		
		DTXScatterPlotViewPoint* additionalPoint = nil;
		if(hasAdditionalPoints)
		{
			additionalPoint = [self.dataSource plotView:self additionalPointAtIndex:idx];
			NSParameterAssert(additionalPoint != nil);
		}
		
		[self _insertPoint:point additionalPoint:additionalPoint atIndex:idx];
	}
	
	[self setNeedsDisplay:YES];
	
	//	CFTimeInterval end = CACurrentMediaTime();
	//	NSLog(@"Took %@s to add %u samples", @(end - start), numberOfPoints);
}

static DTX_ALWAYS_INLINE double __DTXValueAtPosition(DTXScatterPlotView* self, NSArray<DTXScatterPlotViewPoint*>* _points, double plotClickPosition, BOOL isStepped, NSEdgeInsets insets, BOOL isFlipped, BOOL exact, double* delegateClickPosition, double* delegateValue)
{
	double pointRange = _points.lastObject.x - _points.firstObject.x;
	
	NSUInteger idx = 0;
	if(self.previousIndexOf >= _points.count)
	{
		self.previousIndexOf = _points.count - 1;
	}
	
	if(fabs(_points[self.previousIndexOf].x - plotClickPosition) > pointRange / 4)
	{
		DTXScatterPlotViewPoint* testPoint = [DTXScatterPlotViewPoint new];
		testPoint.x = plotClickPosition;

		idx = [_points indexOfObject:testPoint inSortedRange:NSMakeRange(0, _points.count) options:NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual usingComparator:^NSComparisonResult(DTXScatterPlotViewPoint*  _Nonnull obj1, DTXScatterPlotViewPoint*  _Nonnull obj2) {
			if(obj1.x == obj2.x)
			{
				return NSOrderedSame;
			}

			if(obj1.x < obj2.x)
			{
				return NSOrderedAscending;
			}

			return NSOrderedDescending;
		}];
	}
	else
	{
		if(plotClickPosition <= _points.firstObject.x)
		{
			idx = 0;
		}
		else if(plotClickPosition >= _points.lastObject.x)
		{
			idx = _points.count;
		}
		else
		{
			idx = self.previousIndexOf;
			if(plotClickPosition < _points[self.previousIndexOf].x)
			{
				while(_points[idx - 1].x > plotClickPosition && idx > 0)
				{
					idx--;
				}
			}
			else
			{
				while(_points[idx].x <= plotClickPosition && idx <= _points.count)
				{
					idx++;
				}
			}
		}
	}
	
	*delegateClickPosition = 0;
	*delegateValue = 0;
	
	if(idx == 0)
	{
		if(_points.count == 0)
		{
			idx = NSNotFound;
		}
		else
		{
			DTXScatterPlotViewPoint* point = _points[idx];
			*delegateClickPosition = point.x;
			*delegateValue = point.y;
		}
	}
	else if(idx == _points.count)
	{
		idx = idx - 1;
		DTXScatterPlotViewPoint* point = _points[idx];
		*delegateClickPosition = point.x;
		*delegateValue = point.y;
	}
	else
	{
		DTXScatterPlotViewPoint* point1 = _points[idx - 1];
		DTXScatterPlotViewPoint* point2 = _points[idx];
		
		*delegateClickPosition = plotClickPosition;
		if(isStepped || exact)
		{
			*delegateValue = point1.y;
		}
		else
		{
			*delegateValue = lerp(point1.y, point2.y, (plotClickPosition - point1.x) / (point2.x - point1.x));
		}
	}
	
	self.previousIndexOf = idx;
	
	return idx;
}

- (double)valueAtPlotPosition:(double)position exact:(BOOL)exact
{
	double throwAwayPosition;
	double rv;
	__DTXValueAtPosition(self, _points, position, self.isStepped, self.insets, self.isFlipped, exact, &throwAwayPosition, &rv);
	
	return rv;
}

- (double)additionalValueAtPlotPosition:(double)position exact:(BOOL)exact
{
	double throwAwayPosition;
	double rv;
	__DTXValueAtPosition(self, _additionalPoints, position, self.isStepped, self.insets, self.isFlipped, exact, &throwAwayPosition, &rv);
	
	return rv;
}

- (double)valueOfPointIndex:(NSUInteger)idx
{
	return _points[idx].y;
}

- (double)additionalValueOfPointIndex:(NSUInteger)idx
{
	return _additionalPoints[idx].y;
}

- (NSUInteger)indexOfPointAtViewPosition:(CGFloat)viewPosition positionInPlot:(out double *)position valueAtPlotPosition:(out double *)value
{
	if(_points.count == 0)
	{
		return NSNotFound;
	}
	
	double plotClickPosition = self.plotRange.position + viewPosition * self.plotRange.length / self.bounds.size.width;
	
	double throwAwayPosition;
	double throwAwayValue;

	if(position == NULL)
	{
		position = &throwAwayPosition;
	}
	
	if(value == NULL)
	{
		value = &throwAwayValue;
	}
	
	return __DTXValueAtPosition(self, _points, plotClickPosition, self.isStepped, self.insets, self.isFlipped, NO, position, value);
}

- (void)_clicked:(NSClickGestureRecognizer *)cgr
{
	CGPoint clickPoint = [cgr locationInView:self];
	double delegateClickPosition;
	double delegateValue;
	
	NSUInteger idx = [self indexOfPointAtViewPosition:clickPoint.x positionInPlot:&delegateClickPosition valueAtPlotPosition:&delegateValue];
	
	[self.delegate plotView:self didClickPointAtIndex:idx clickPositionInPlot:delegateClickPosition valueAtClickPosition:delegateValue];
}

@end
