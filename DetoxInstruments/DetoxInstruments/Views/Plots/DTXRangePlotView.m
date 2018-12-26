//
//  DTXRangePlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXRangePlotView.h"

@implementation DTXRange

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> start: %f end: %f height: %f", self.className, self, self.start, self.end, self.height];
}

@end

@implementation DTXRangePlotView
{
	double _totalHeightLines;
	NSMutableArray* _distinctColors;
	NSMapTable* _distinctColorLines;
	
	NSMutableArray* _lines;
	
	NSSize _cachedIntrinsicContentSize;
}

@dynamic delegate;
@dynamic dataSource;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		self.wantsLayer = YES;
		self.layer.drawsAsynchronously = YES;
		//For furure live resize support.
//		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
//		self.layerContentsPlacement = NSViewLayerContentsPlacementLeft;
		_lineHeight = 5.0;
		_lineSpacing = 4.0;
		self.insets = NSEdgeInsetsMake(5, 0, 5, 0);
	}
	
	return self;
}

- (BOOL)isFlipped
{
	return YES;
}

//- (BOOL)canDrawConcurrently
//{
//	return YES;
//}

- (void)setLineHeight:(double)lineHeight
{
	_lineHeight = lineHeight;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)setLineSpacing:(double)lineSpacing
{
	_lineSpacing = lineSpacing;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)_insertSample:(DTXRange*)sample atIndex:(NSUInteger)idx
{
	_lines[idx] = sample;
	
	_totalHeightLines = MAX(_totalHeightLines, sample.height);
	
	NSMutableSet* linesForColor = [_distinctColorLines objectForKey:sample.color];
	if(linesForColor == nil)
	{
		[_distinctColors addObject:sample.color];
		linesForColor = [NSMutableSet new];
		[_distinctColorLines setObject:linesForColor forKey:sample.color];
	}
	
	[linesForColor addObject:sample];
}

- (void)reloadData
{
//	CFTimeInterval start = CACurrentMediaTime();
	
	@autoreleasepool
	{
		double oldHeight = _totalHeightLines;
		_totalHeightLines = 0;
		
		NSUInteger count = [self.dataSource numberOfSamplesInPlotView:self];
		
		_distinctColors = [[NSMutableArray alloc] initWithCapacity:count];
		_distinctColorLines = [NSMapTable strongToStrongObjectsMapTable];
		_lines = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(NSUInteger idx = 0; idx < count; idx++)
		{
			DTXRange* sample = [self.dataSource plotView:self rangeAtIndex:idx];
			
			NSParameterAssert(sample != nil);
			
			if(sample.color == nil)
			{
				sample.color = NSColor.textColor;
			}
			
			[self _insertSample:sample atIndex:idx];
		}
		
		[super reloadData];
		
		if(_totalHeightLines != oldHeight)
		{
			[self invalidateIntrinsicContentSize];
		}
	}
	
//	CFTimeInterval end = CACurrentMediaTime();
//	NSLog(@"Took %@s to reload data", @(end - start));
}

- (void)reloadRangeAtIndex:(NSUInteger)idx
{
//	CFTimeInterval start = CACurrentMediaTime();
	
	DTXRange* sample = _lines[idx];
	DTXRange* newSample = [self.dataSource plotView:self rangeAtIndex:idx];
	
	NSParameterAssert(newSample != nil);
	
	if(newSample.color == nil)
	{
		newSample.color = NSColor.textColor;
	}

	NSMutableSet* linesForColor = [_distinctColorLines objectForKey:sample.color];
	[linesForColor removeObject:sample];
	[self _insertSample:newSample atIndex:idx];
	
	if(sample.start == newSample.start && sample.end == newSample.end && sample.height == newSample.height)
	{
		CGRect selfBounds = self.bounds;
		double viewHeightRatio = MIN(1.0, selfBounds.size.height / self.intrinsicContentSize.height);
		double lineHeight = viewHeightRatio * self.lineHeight;
		double topInset = viewHeightRatio * self.insets.top;
		double spacing = viewHeightRatio * (self.lineHeight + self.lineSpacing);
		
		CGFloat graphViewRatio = selfBounds.size.width / self.plotRange.lengthDouble;
		CGFloat offset = - graphViewRatio * self.plotRange.locationDouble;
		
		double start = offset + newSample.start * graphViewRatio;
		double end = offset + newSample.end * graphViewRatio;
		CGFloat height = spacing * newSample.height + lineHeight / 2.0 + topInset;
		
		//Only draw the area around the sample.
		[self setNeedsDisplayInRect:NSMakeRect(start, height - lineHeight / 2.0, end - start, lineHeight)];
		
		return;
	}
	
	[self setNeedsDisplay:YES];
	
//	CFTimeInterval end = CACurrentMediaTime();
//	NSLog(@"Took %@s to reload sample", @(end - start));
}

- (NSSize)intrinsicContentSize
{
	return _cachedIntrinsicContentSize;
}

- (void)invalidateIntrinsicContentSize
{
	_cachedIntrinsicContentSize = NSMakeSize(NSViewNoIntrinsicMetric, (self.lineHeight + self.lineSpacing) * _totalHeightLines + self.lineHeight + self.insets.bottom + self.insets.top);
	
	[super invalidateIntrinsicContentSize];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[super invalidateIntrinsicContentSize];
		});
	});
}

- (void)drawRect:(NSRect)dirtyRect
{
//	CFTimeInterval start = CACurrentMediaTime();
//	NSUInteger linesDrawn = 0;
	
	CPTPlotRange* globalXRange = self.globalPlotRange;
	CPTPlotRange* xRange = self.plotRange;
	
	NSParameterAssert(globalXRange != nil);
	NSParameterAssert(globalXRange.locationDouble == 0);
	NSParameterAssert(xRange != nil);
	
	CGRect selfBounds = self.bounds;
	double viewHeightRatio = MIN(1.0, selfBounds.size.height / self.intrinsicContentSize.height);
	double lineHeight = viewHeightRatio * self.lineHeight;
	double topInset = viewHeightRatio * self.insets.top;
	double spacing = viewHeightRatio * (self.lineHeight + self.lineSpacing);
	
	CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
	CGFloat offset = - graphViewRatio * xRange.locationDouble;
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextSetLineWidth(ctx, lineHeight);
	CGContextSetLineCap(ctx, kCGLineCapButt);
//	CGContextSetAllowsAntialiasing(ctx, NO);
//	CGContextSetShouldAntialias(ctx, NO);
	
	for (NSColor* distinctColor in _distinctColors)
	{
		CGContextSetStrokeColorWithColor(ctx, [distinctColor CGColor]);
		CGContextSetFillColorWithColor(ctx, [distinctColor CGColor]);
		
//		BOOL didAddLine = NO;
		
		for(DTXRange* line in [_distinctColorLines objectForKey:distinctColor])
		{
			double start = MAX(dirtyRect.origin.x, offset + line.start * graphViewRatio);
			double end = MIN(dirtyRect.origin.x + dirtyRect.size.width, offset + line.end * graphViewRatio);
			CGFloat height = spacing * line.height + lineHeight / 2.0 + topInset;
			
			//Out of bounds lines should not be drawn
			if(height < dirtyRect.origin.y ||
			   height > dirtyRect.origin.y + dirtyRect.size.height ||
			   end < dirtyRect.origin.x ||
			   start > dirtyRect.origin.x + dirtyRect.size.width)
			{
				continue;
			}
			
			if(start != end)
			{
				CGContextMoveToPoint(ctx, start, height);
				CGContextAddLineToPoint(ctx, end, height);
//				linesDrawn++;
//				didAddLine = YES;
				CGContextStrokePath(ctx);
			}
			else
			{
				CGContextFillEllipseInRect(ctx, CGRectMake(start - lineHeight / 2, height - lineHeight / 2, lineHeight, lineHeight));
			}
		}
		
//		if(didAddLine)
//		{
//			CGContextStrokePath(ctx);
//		}
	}
	
	[super drawRect:dirtyRect];
	
//	CFTimeInterval end = CACurrentMediaTime();
//	NSLog(@"Took %fs to render %lu lines", end - start, linesDrawn);
}

- (void)_clicked:(NSClickGestureRecognizer*)cgr
{
	CGPoint clickPoint = [cgr locationInView:self];

	CGRect selfBounds = self.bounds;
	double viewHeightRatio = selfBounds.size.height / self.intrinsicContentSize.height;
	double lineHeight = viewHeightRatio * self.lineHeight;
	double topInset = viewHeightRatio * self.insets.top;
	double spacing = viewHeightRatio * (self.lineHeight + self.lineSpacing);
	
	CPTPlotRange* xRange = self.plotRange;
	double previousLocation = xRange.locationDouble;
	
	double pointOnGraph = previousLocation + clickPoint.x * xRange.lengthDouble / selfBounds.size.width;
	
	BOOL found = NO;
	NSUInteger idx = 0;
	for(DTXRange* line in _lines)
	{
		CGFloat height = spacing * line.height + lineHeight / 2.0 + topInset;
		
		if(line.start != line.end && (line.end < pointOnGraph ||
									  line.start > pointOnGraph ||
									  fabs(height - clickPoint.y) > ((0.5 * spacing) + lineHeight) / 2.0)
		   )
		{
			idx++;
			continue;
		}
		
		double lineHeightOnGraph = lineHeight * xRange.lengthDouble / selfBounds.size.width;
		
		if(line.start == line.end && (fabs(line.start - pointOnGraph) > lineHeightOnGraph / 2.0 ||
									  fabs(height - clickPoint.y) > ((0.5 * spacing) + lineHeight) / 2.0)
		   )
		{
			idx++;
			continue;
		}
		
		found = YES;
		break;
	}
	
	if(found == YES)
	{
		[self.delegate plotView:self didClickRangeAtIndex:idx];
	}
}

@end
