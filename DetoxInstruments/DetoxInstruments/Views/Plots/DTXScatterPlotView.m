//
//  DTXScatterPlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/30/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXScatterPlotView-Private.h"

@interface DTXScatterPlotView ()

@property (nonatomic, strong) NSMutableArray<DTXScatterPlotViewPoint*>* _points;

@end

static inline __attribute__((always_inline)) double __DTXValueAtIndex(NSArray<DTXScatterPlotViewPoint*>* points, DTXScatterPlotViewPoint* point, double test, NSUInteger idx, double graphHeightViewRatio)
{
	if(test == 1)
	{
		return graphHeightViewRatio * point.y;
	}
	else
	{
		double value = 0;
		for(NSUInteger innerIdx = idx; innerIdx < idx + test && innerIdx + 1 < points.count; innerIdx++)
		{
			DTXScatterPlotViewPoint* point = [points objectAtIndex:innerIdx];
			value = MAX(value, (graphHeightViewRatio * point.y));
		}
		return value;
	}
}

static inline __attribute__((always_inline)) void __DTXStartPaths(CGMutablePathRef* closedPath, CGMutablePathRef* openPath, NSEdgeInsets insets, BOOL isFlipped, CGFloat position, CGFloat value, BOOL isStepped)
{
	*closedPath = CGPathCreateMutable();
	*openPath = CGPathCreateMutable();
	CGPathMoveToPoint(*closedPath, NULL, position, __DTXBottomInset(insets, isFlipped));
	CGPathAddLineToPoint(*closedPath, NULL, position, value);
	CGPathMoveToPoint(*openPath, NULL, position, value);
}

static inline __attribute__((always_inline)) void __DTXFlushPaths(DTXScatterPlotView* self, CGContextRef ctx, CGMutablePathRef closedPath, CGMutablePathRef openPath, CGFloat position, NSUInteger drawingType)
{
	CGPathAddLineToPoint(closedPath, NULL, position, __DTXBottomInset(self.insets, self.isFlipped));
	
	CGContextAddPath(ctx, closedPath);
	CGContextClip(ctx);
	
	NSColor* fillColor1 = self.fillColor1;
	NSColor* fillColor2 = self.fillColor2;
	
	if(drawingType == 1)
	{
		
		fillColor1 = [NSColor.systemGrayColor colorWithAlphaComponent:fillColor1.alphaComponent * 0.2];
		fillColor2 = [NSColor.systemGrayColor colorWithAlphaComponent:fillColor2.alphaComponent * 0.2];
	}
	
	if([fillColor1 isEqualTo:fillColor2] == NO)
	{
		CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)@[(__bridge id)fillColor1.CGColor, (__bridge id)fillColor2.CGColor], NULL);
		CGContextDrawLinearGradient(ctx, gradient, CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)), CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)), 0);
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
	
	NSColor* lineColor = self.lineColor;
	
	if(drawingType == 1)
	{
		lineColor = [NSColor.systemGrayColor colorWithAlphaComponent:lineColor.alphaComponent * 0.5];
	}
	
	if(self.lineWidth > 0.0 && self.lineColor.alphaComponent > 0.0)
	{
		CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
		CGContextSetLineWidth(ctx, self.lineWidth);
		CGContextAddPath(ctx, openPath);
		CGContextStrokePath(ctx);
	}
	
	CGPathRelease(closedPath);
	CGPathRelease(openPath);
}

static inline __attribute__((always_inline)) void __DTXDrawPoints(DTXScatterPlotView* self, CGContextRef ctx)
{
	NSMutableArray<DTXScatterPlotViewPoint*>* points = self._points;
	CPTPlotRange* plotRange = self.plotRange;
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
	
	CGFloat graphViewRatio = selfBounds.size.width / plotRange.lengthDouble;
	CGFloat graphHeightViewRatio = (selfBounds.size.height - insets.top - insets.bottom) / (maxHeight * self.plotHeightMultiplier);
	CGFloat offset = - graphViewRatio * plotRange.locationDouble;
	
	NSUInteger firstPointIdx = 0;
	NSUInteger lastPointIdx = points.count - 1;
	
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
	double oldValue = graphHeightViewRatio * point.y + __DTXBottomInset(insets, isFlipped);
	
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
	
	for(NSUInteger idx = firstPointIdx + 1; idx <= lastPointIdx; idx += 1 /*test*/)
	{
		point = [points objectAtIndex:idx];
		double nextPosition = offset + graphViewRatio * point.x;
		double nextValue = __DTXValueAtIndex(points, point, test, idx, graphHeightViewRatio) + __DTXBottomInset(insets, isFlipped);
			
		while(currentZoneIdx < zones.count - 1 && nextPosition > zones[currentZoneIdx + 1].start)
		{
			double nextZoneStart = zones[currentZoneIdx + 1].start;
			
			double midPosition = nextZoneStart;
			
			if(isStepped)
			{
				CGPathAddLineToPoint(closedPath, NULL, midPosition, oldValue);
				CGPathAddLineToPoint(openPath, NULL, midPosition, oldValue);
				
				__DTXFlushPaths(self, ctx, closedPath, openPath, midPosition, zones[currentZoneIdx].drawingType);
				__DTXStartPaths(&closedPath, &openPath, insets, isFlipped, midPosition, oldValue, isStepped);
				
				CGPathAddLineToPoint(closedPath, NULL, nextPosition, oldValue);
				CGPathAddLineToPoint(openPath, NULL, nextPosition, oldValue);
			}
			else
			{
				double midValue = lerp(oldValue, nextValue, (midPosition - oldPosition) / (nextPosition - oldPosition));
				
				CGPathAddLineToPoint(closedPath, NULL, midPosition, midValue);
				CGPathAddLineToPoint(openPath, NULL, midPosition, midValue);
				
				__DTXFlushPaths(self, ctx, closedPath, openPath, midPosition, zones[currentZoneIdx].drawingType);
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
	
	__DTXFlushPaths(self, ctx, closedPath, openPath, oldPosition, zones[currentZoneIdx].drawingType);
}

@implementation DTXScatterPlotViewPoint

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> x: %@ y: %@", self.className, self, @(self.x), @(self.y)];
}

@end

@interface _DTXLineLayer : CALayer

@property (nonatomic, weak) DTXScatterPlotView* view;

@end

@implementation _DTXLineLayer

- (instancetype)init
{
	self = [super init];
	
	self.drawsAsynchronously = NO;
	
	return self;
}

- (id<CAAction>)actionForKey:(NSString *)event
{
	return nil;
}

- (BOOL)canDrawConcurrently
{
	return YES;
}

- (void)drawInContext:(CGContextRef)ctx
{
	__DTXDrawPoints(_view, ctx);
}

@end

@implementation DTXScatterPlotView
{
	_DTXLineLayer* _layer;
}

@dynamic dataSource, delegate;
@synthesize _points=_points;
@synthesize maxHeight=_maxHeight;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		self.wantsLayer = YES;
		self.layer.drawsAsynchronously = NO;
		//For furure live resize support.
		//		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
		//		self.layerContentsPlacement = NSViewLayerContentsPlacementLeft;
		_lineWidth = 1.0;
		self.insets = NSEdgeInsetsZero;
		self.plotHeightMultiplier = 1.0;
		
		//		_layer = _DTXLineLayer.layer;
		//		_layer.view = self;
		//		[self.layer addSublayer:_layer];
		//		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
	}
	
	return self;
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	_layer.frame = self.bounds;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[_layer setNeedsDisplayInRect:dirtyRect];
//}

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	__DTXDrawPoints(self, ctx);
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

- (void)_insertPoint:(DTXScatterPlotViewPoint*)point atIndex:(NSUInteger)idx
{
	_points[idx] = point;
	
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

- (void)reloadData
{
	//	CFTimeInterval start = CACurrentMediaTime();
	
	@autoreleasepool
	{
		NSUInteger count = [self.dataSource numberOfSamplesInPlotView:self];
		
		_points = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(NSUInteger idx = 0; idx < count; idx++)
		{
			DTXScatterPlotViewPoint* point = [self.dataSource plotView:self pointAtIndex:idx];
			NSParameterAssert(point != nil);
			
			[self _insertPoint:point atIndex:idx];
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
	
	[self _insertPoint:newPoint atIndex:index];
	
	[self setNeedsDisplay:YES];
	
	//	CFTimeInterval end = CACurrentMediaTime();
	//	NSLog(@"Took %@s to reload sample", @(end - start));
}

- (void)addNumberOfPoints:(NSUInteger)numberOfPoints
{
	//	CFTimeInterval start = CACurrentMediaTime();
	
	NSUInteger count = _points.count + numberOfPoints;
	for(NSUInteger idx = _points.count; idx < count; idx++)
	{
		DTXScatterPlotViewPoint* point = [self.dataSource plotView:self pointAtIndex:idx];
		
		NSParameterAssert(point != nil);
		
		[self _insertPoint:point atIndex:idx];
	}
	
	[self setNeedsDisplay:YES];
	
	//	CFTimeInterval end = CACurrentMediaTime();
	//	NSLog(@"Took %@s to add %u samples", @(end - start), numberOfPoints);
}

static inline __attribute__((always_inline)) double __DTXValueAtPosition(DTXScatterPlotView* self, NSArray<DTXScatterPlotViewPoint*>* _points, double plotClickPosition, BOOL isStepped, NSEdgeInsets insets, BOOL isFlipped, double* delegateClickPosition, double* delegateValue)
{
	double pointRange = _points.lastObject.x - _points.firstObject.x;
	
	NSUInteger idx = 0;
	if(fabs(_points[self.previousIndexOf].x - plotClickPosition) > pointRange / 4)
	{
		DTXScatterPlotViewPoint* testPoint = [DTXScatterPlotViewPoint new];
		testPoint.x = plotClickPosition;

		idx = [_points indexOfObject:testPoint inSortedRange:NSMakeRange(0, _points.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(DTXScatterPlotViewPoint*  _Nonnull obj1, DTXScatterPlotViewPoint*  _Nonnull obj2) {
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
				while(_points[idx].x > plotClickPosition && idx >= 0)
				{
					idx--;
				}
			}
			else
			{
				while(_points[idx + 1].x < plotClickPosition && idx < _points.count)
				{
					idx++;
				}
			}
			
			if(idx < _points.count)
			{
				idx += 1;
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
		
		if(fabs(point1.x - plotClickPosition) < fabs(point2.x - plotClickPosition))
		{
			idx = idx - 1;
		}
		
		*delegateClickPosition = plotClickPosition;
		if(isStepped)
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

- (double)valueAtPlotPosition:(double)position
{
	double throwAwayPosition;
	double rv;
	__DTXValueAtPosition(self, _points, position, self.isStepped, self.insets, self.isFlipped, &throwAwayPosition, &rv);
	
	return rv;
}

- (double)valueOfPointIndex:(NSUInteger)idx
{
	return _points[idx].y;
}

- (NSUInteger)indexOfPointAtViewPosition:(CGFloat)viewPosition positionInPlot:(out double *)position valueAtPlotPosition:(out double *)value
{
	if(_points.count == 0)
	{
		return NSNotFound;
	}
	
	double plotClickPosition = self.plotRange.locationDouble + viewPosition * self.plotRange.lengthDouble / self.bounds.size.width;
	
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
	
	return __DTXValueAtPosition(self, _points, plotClickPosition, self.isStepped, self.insets, self.isFlipped, position, value);
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
