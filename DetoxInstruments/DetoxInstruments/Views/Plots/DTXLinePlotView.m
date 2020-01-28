//
//  DTXLinePlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/22/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXLinePlotView.h"
#import "DTXScatterPlotView-Private.h"
#import "NSAppearance+UIAdditions.h"
@import ObjectiveC;

@interface DTXScatterPlotView ()

@property (nonatomic, strong) NSMutableArray<DTXScatterPlotViewPoint*>* _points;
@property (nonatomic, strong) NSMutableArray<DTXScatterPlotViewPoint*>* _additionalPoints;

@end

static DTX_ALWAYS_INLINE double __DTXValueAtIndex(NSArray<DTXScatterPlotViewPoint*>* points, DTXScatterPlotViewPoint* point, NSUInteger idx, double graphHeightViewRatio, BOOL hideLower)
{
	return graphHeightViewRatio * point.y;
}

static DTX_ALWAYS_INLINE void __DTXFlushPath(DTXScatterPlotView* self, NSColor* lineColor, CGContextRef ctx, CGMutablePathRef path, NSUInteger drawingType)
{
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
		CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
		CGContextSetLineWidth(ctx, self.lineWidth);
		CGContextAddPath(ctx, path);
		CGContextStrokePath(ctx);
	}
	
	CGPathRelease(path);
}

static DTX_ALWAYS_INLINE void __DTXDrawPoints(DTXScatterPlotView* self, NSArray<DTXScatterPlotViewPoint*>* points, NSColor* fillColor1, NSColor* fillColor2, double fillStartValue, double fillLimitValue, NSColor* lineColor, BOOL dashedLine, CGContextRef ctx)
{
	DTXPlotRange* plotRange = self.plotRange;
	double maxHeight = (self.heightSynchronizer ? self.heightSynchronizer.maximumPlotHeight : self.maxHeight);
	NSEdgeInsets insets = self.insets;
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
	double firstPointPosition = offset + graphViewRatio * point.x;
	
	NSUInteger currentZoneIdx = 0;
	for(NSUInteger idx = 0; idx < zones.count; idx++)
	{
		_DTXDrawingZone* zone = zones[idx];
		if(zone.start <= firstPointPosition)
		{
			currentZoneIdx = idx;
		}
	}
	
	CGMutablePathRef path = CGPathCreateMutable();
	for(NSUInteger idx = firstPointIdx; idx <= lastPointIdx; idx += 1)
	{
		point = [points objectAtIndex:idx];
		double position = offset + graphViewRatio * point.x;
		double value = __DTXValueAtIndex(points, point, idx, graphHeightViewRatio, dashedLine) + __DTXBottomInset(insets, isFlipped);
			
		while(currentZoneIdx < zones.count - 1 && position > zones[currentZoneIdx + 1].start)
		{
			__DTXFlushPath(self, self.lineColor, ctx, path, zones[currentZoneIdx].drawingType);
			path = CGPathCreateMutable();
			
			currentZoneIdx++;
		}
		
		CGPathMoveToPoint(path, NULL, position, __DTXBottomInset(insets, isFlipped));
		CGPathAddLineToPoint(path, NULL, position, value);
	}
	
	__DTXFlushPath(self, self.lineColor, ctx, path, zones[currentZoneIdx].drawingType);
}

@implementation DTXLinePlotView

- (void)drawRect:(NSRect)dirtyRect
{
	if(self.isDataLoaded == NO)
	{
		[self reloadData];
	}
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	__DTXDrawPoints(self, self._points, self.fillColor1, self.fillColor2, -1.0, -1.0, self.lineColor, NO, ctx);
	if(self._additionalPoints != nil)
	{
		__DTXDrawPoints(self, self._additionalPoints, self.additionalFillColor1 ?: self.fillColor1, self.additionalFillColor2 ?: self.fillColor2, self.additionalFillStartValue, self.additionalFillLimitValue, self.additionalLineColor ?: NSColor.clearColor, YES, ctx);
	}
	
	struct objc_super super = {.receiver = self, .super_class = DTXPlotView.class};
	void (*super_class)(struct objc_super*, SEL, NSRect) = (void*)objc_msgSendSuper;
	super_class(&super, _cmd, dirtyRect);
}

static DTX_ALWAYS_INLINE double __DTXValueAtPosition(DTXScatterPlotView* self, NSArray<DTXScatterPlotViewPoint*>* _points, double plotClickPosition, NSEdgeInsets insets, BOOL isFlipped, double* delegateClickPosition, double* delegateValue)
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
		*delegateClickPosition = _points[idx].x;
		*delegateValue = _points[idx].y;
	}
	
	self.previousIndexOf = idx;
	
	return idx;
}

- (NSUInteger)indexOfPointAtViewPosition:(CGFloat)viewPosition positionInPlot:(out double *)position valueAtPlotPosition:(out double *)value
{
	if(self._points.count == 0)
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
	
	return __DTXValueAtPosition(self, self._points, plotClickPosition, self.insets, self.isFlipped, position, value);
}

@end
