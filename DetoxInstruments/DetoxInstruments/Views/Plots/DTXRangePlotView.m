//
//  DTXRangePlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPlotView-Private.h"
#import "DTXRangePlotView.h"

const CGFloat DTXRangePlotViewDefaultLineWidth = 6.0;
const CGFloat DTXRangePlotViewDefaultLineSpacing = 4.0;

@interface DTXRangePlotViewRange ()

@property (nonatomic, strong) NSAttributedString* titleToDraw;

@end

@implementation DTXRangePlotViewRange

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
	
	NSDictionary* _stringDrawingAttributes;
	NSSize _fontCharacterSize;
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
		_lineWidth = DTXRangePlotViewDefaultLineWidth;
		_lineSpacing = DTXRangePlotViewDefaultLineSpacing;
		self.insets = NSEdgeInsetsMake(5, 0, 5, 0);
		
		NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		style.lineBreakMode = NSLineBreakByTruncatingTail;
		style.allowsDefaultTighteningForTruncation = NO;
		
		_stringDrawingAttributes = @{NSFontAttributeName: [NSFont userFixedPitchFontOfSize:NSFont.smallSystemFontSize], NSParagraphStyleAttributeName: style};
		
		self.flipped = YES;
		
		[self setDrawTitles:NO];
	}
	
	return self;
}

//- (BOOL)canDrawConcurrently
//{
//	return YES;
//}

- (void)setDrawTitles:(BOOL)drawTitles
{
	_drawTitles = drawTitles;
	
	if(_drawTitles)
	{
		_fontCharacterSize = [@"A" sizeWithAttributes:_stringDrawingAttributes];
	}
	else
	{
		_fontCharacterSize = CGSizeZero;
	}
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)setLineWidth:(double)lineHeight
{
	_lineWidth = lineHeight;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)setLineSpacing:(double)lineSpacing
{
	_lineSpacing = lineSpacing;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)_insertRange:(DTXRangePlotViewRange*)sample atIndex:(NSUInteger)idx
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

- (void)_prepareRangeForUsage:(DTXRangePlotViewRange*)range
{
	if(range.color == nil)
	{
		range.color = NSColor.textColor;
	}
	
	if(range.title.length > 0)
	{
		if(range.titleColor == nil)
		{
			range.titleColor = NSColor.textBackgroundColor;
		}
		
		NSMutableDictionary* attrs = [_stringDrawingAttributes mutableCopy];
		attrs[NSForegroundColorAttributeName] = range.titleColor;
		range.titleToDraw = [[NSAttributedString alloc] initWithString:range.title attributes:attrs];
	}
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
			DTXRangePlotViewRange* range = [self.dataSource plotView:self rangeAtIndex:idx];
			
			NSParameterAssert(range != nil);
			
			[self _prepareRangeForUsage:range];
			
			[self _insertRange:range atIndex:idx];
		}
		
		[super reloadData];
		
		if(_totalHeightLines != oldHeight)
		{
			[self invalidateIntrinsicContentSize];
		}
		
		[self setNeedsDisplay:YES];
	}
	
//	CFTimeInterval end = CACurrentMediaTime();
//	NSLog(@"Took %@s to reload data", @(end - start));
}

- (void)reloadRangeAtIndex:(NSUInteger)idx
{
//	CFTimeInterval start = CACurrentMediaTime();
	
	DTXRangePlotViewRange* range = _lines[idx];
	DTXRangePlotViewRange* newRange = [self.dataSource plotView:self rangeAtIndex:idx];
	
	NSParameterAssert(newRange != nil);
	
	[self _prepareRangeForUsage:newRange];

	NSMutableSet* linesForColor = [_distinctColorLines objectForKey:range.color];
	[linesForColor removeObject:range];
	[self _insertRange:newRange atIndex:idx];
	
	if(range.start == newRange.start && range.end == newRange.end && range.height == newRange.height)
	{
		CGRect selfBounds = self.bounds;
		double viewHeightRatio = MIN(1.0, selfBounds.size.height / self.intrinsicContentSize.height);
		double lineHeight = viewHeightRatio * (_lineWidth + _fontCharacterSize.height);
		double topInset = viewHeightRatio * self.insets.top;
		double spacing = viewHeightRatio * (_lineWidth + _fontCharacterSize.height + _lineSpacing);
		
		CGFloat graphViewRatio = selfBounds.size.width / self.plotRange.lengthDouble;
		CGFloat offset = - graphViewRatio * self.plotRange.locationDouble;
		
		double start = offset + newRange.start * graphViewRatio;
		double end = offset + newRange.end * graphViewRatio;
		CGFloat height = spacing * newRange.height + lineHeight / 2.0 + topInset;
		
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
	CGFloat oldHeight = _cachedIntrinsicContentSize.height;
	
	_cachedIntrinsicContentSize = NSMakeSize(NSViewNoIntrinsicMetric, MAX(self.minimumHeight, (_lineWidth + _fontCharacterSize.height + _lineSpacing) * _totalHeightLines + _lineWidth + _fontCharacterSize.height + self.insets.bottom + self.insets.top));
	
	if(oldHeight != _cachedIntrinsicContentSize.height)
	{
		[super invalidateIntrinsicContentSize];
		
	
//		dispatch_async(dispatch_get_main_queue(), ^{
//			dispatch_async(dispatch_get_main_queue(), ^{
//				[super invalidateIntrinsicContentSize];
//			});
//		});
	}
}

static
DTX_ALWAYS_INLINE
void __DTXDrawLinesFastPath(DTXRangePlotView* self, CGContextRef ctx, NSRect dirtyRect)
{
	CPTPlotRange* globalXRange = self.globalPlotRange;
	CPTPlotRange* xRange = self.plotRange;
	
	NSCParameterAssert(globalXRange != nil);
	NSCParameterAssert(globalXRange.locationDouble == 0);
	NSCParameterAssert(xRange != nil);
	
	CGRect selfBounds = self.bounds;
	double viewHeightRatio = MIN(1.0, selfBounds.size.height / self.intrinsicContentSize.height);
	double lineHeight = viewHeightRatio * (self->_lineWidth + self->_fontCharacterSize.height);
	double lineHeightWithoutText = viewHeightRatio * (self->_lineWidth);
	double topInset = viewHeightRatio * self.insets.top;
	double spacing = viewHeightRatio * (self->_lineWidth  + self->_fontCharacterSize.height + self->_lineSpacing);
	
	CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
	CGFloat offset = - graphViewRatio * xRange.locationDouble;
	
	CGContextSetLineWidth(ctx, lineHeight);
	CGContextSetLineCap(ctx, kCGLineCapButt);
	
	for (NSColor* distinctColor in self->_distinctColors)
	{
		CGContextSetStrokeColorWithColor(ctx, [distinctColor CGColor]);
		CGContextSetFillColorWithColor(ctx, [distinctColor CGColor]);
		
		for(DTXRangePlotViewRange* line in [self->_distinctColorLines objectForKey:distinctColor])
		{
			NSString* title = line.title;
			
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
				CGContextSetAllowsAntialiasing(ctx, distinctColor.alphaComponent == 1.0);
				CGContextMoveToPoint(ctx, start, height);
				CGContextAddLineToPoint(ctx, end, height);
				CGContextStrokePath(ctx);
				
				if(self->_drawTitles == YES && title.length > 0)
				{
					double spaceToCheck = MIN(5, title.length) * self->_fontCharacterSize.width;
					if(end - start > spaceToCheck + lineHeight / 2)
					{
						CGContextSaveGState(ctx);
						CGContextSetAllowsAntialiasing(ctx, YES);
						[line.titleToDraw drawInRect:NSMakeRect(start + lineHeight / 4, height - self->_fontCharacterSize.height / 2.0 - 1.5, end - start - lineHeight / 2, self->_fontCharacterSize.height)];
						CGContextRestoreGState(ctx);
					}
				}
			}
			else
			{
				CGContextSetAllowsAntialiasing(ctx, YES);
				CGContextFillEllipseInRect(ctx, CGRectMake(start - lineHeightWithoutText / 2, height - lineHeight / 2, lineHeightWithoutText, lineHeight));
			}
		}
	}
}

static DTX_ALWAYS_INLINE void __DTXDrawLinesSlowPath(DTXRangePlotView* self, CGContextRef ctx, NSRect dirtyRect, NSMutableArray<_DTXDrawingZone*>* zones)
{
	CPTPlotRange* globalXRange = self.globalPlotRange;
	CPTPlotRange* xRange = self.plotRange;
	
	NSCParameterAssert(globalXRange != nil);
	NSCParameterAssert(globalXRange.locationDouble == 0);
	NSCParameterAssert(xRange != nil);
	
	CGRect selfBounds = self.bounds;
	double viewHeightRatio = MIN(1.0, selfBounds.size.height / self.intrinsicContentSize.height);
	double lineHeight = viewHeightRatio * (self->_lineWidth + self->_fontCharacterSize.height);
	double lineHeightWithoutText = viewHeightRatio * (self->_lineWidth);
	double topInset = viewHeightRatio * self.insets.top;
	double spacing = viewHeightRatio * (self->_lineWidth  + self->_fontCharacterSize.height + self->_lineSpacing);
	
	CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
	CGFloat offset = - graphViewRatio * xRange.locationDouble;
	
	CGContextSetLineWidth(ctx, lineHeight);
	CGContextSetLineCap(ctx, kCGLineCapButt);
	
	for (NSColor* distinctColor in self->_distinctColors)
	{
//		[NSColor.systemGrayColor blendedColorWithFraction:lineColor.alphaComponent * 0.5 ofColor:NSColor.controlBackgroundColor];
		NSColor* shadedColor = [NSColor.systemGrayColor colorWithAlphaComponent:distinctColor.alphaComponent * 0.2];
		
		for(DTXRangePlotViewRange* line in [self->_distinctColorLines objectForKey:distinctColor])
		{
			NSString* title = line.title;
			
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
				double lastEnd = start;
				for(_DTXDrawingZone* zone in zones)
				{
					if(zone.start < start)
					{
						continue;
					}
					
					lastEnd = MIN(zone.start, end);
					
					CGContextAddLineToPoint(ctx, lastEnd, height);
					//If current zone drawing type is 1, previous was 0.
					NSColor* colorToUse = zone.drawingType == 1 ? distinctColor : shadedColor;
					CGContextSetStrokeColorWithColor(ctx, colorToUse.CGColor);
					CGContextSetAllowsAntialiasing(ctx, colorToUse.alphaComponent == 1.0);
					CGContextStrokePath(ctx);
	
					if(zone.start < end)
					{
						CGContextMoveToPoint(ctx, lastEnd, height);
					}
					else
					{
						break;
					}
				}
				
				if(self->_drawTitles == YES && title.length > 0 && distinctColor.alphaComponent == 1.0)
				{
					double spaceToCheck = MIN(5, title.length) * self->_fontCharacterSize.width  + lineHeight / 2;
					
					if(end - start > spaceToCheck)
					{
						double zeroZoneStart = 0;
						double zeroZoneEnd = 0;
						for(_DTXDrawingZone* zone in zones)
						{
							if(zone.nextZone != nil && zone.nextZone.start < start)
							{
								continue;
							}
							
							if(zone.drawingType != 0)
							{
								continue;
							}
							
							zeroZoneStart = MAX(0, MAX(start, zone.start));
							zeroZoneEnd = MIN(end, (zone.nextZone == nil ? DBL_MAX : zone.nextZone.start));
							
							break;
						}
						
						if(zeroZoneEnd - zeroZoneStart > spaceToCheck)
						{
							CGContextSaveGState(ctx);
							CGContextSetAllowsAntialiasing(ctx, YES);
							[line.titleToDraw drawInRect:NSMakeRect(zeroZoneStart + lineHeight / 4, height - self->_fontCharacterSize.height / 2.0 - 1.5, zeroZoneEnd - zeroZoneStart - lineHeight / 2, self->_fontCharacterSize.height)];
							CGContextRestoreGState(ctx);
						}
					}
				}
			}
			else
			{
				for(_DTXDrawingZone* zone in zones)
				{
					if(zone.start < start)
					{
						continue;
					}
					
					NSColor* colorToUse = zone.drawingType == 1 ? distinctColor : shadedColor;
					CGContextSetFillColorWithColor(ctx, colorToUse.CGColor);
					CGContextSetAllowsAntialiasing(ctx, YES);
					CGContextFillEllipseInRect(ctx, CGRectMake(start - lineHeightWithoutText / 2, height - lineHeight / 2, lineHeightWithoutText, lineHeight));
					
					break;
				}
			}
		}
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
//	CFTimeInterval start = CACurrentMediaTime();
//	NSUInteger linesDrawn = 0;
	
	NSMutableArray<_DTXDrawingZone*>* zones;
	if(self._hasRangeAnnotations)
	{
		zones = [NSMutableArray new];
		__DTXFillZones(self, zones);
	}
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	if(zones.count <= 1)
	{
		__DTXDrawLinesFastPath(self, ctx, dirtyRect);
	}
	else
	{
		__DTXDrawLinesSlowPath(self, ctx, dirtyRect, zones);
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
	double lineHeight = viewHeightRatio * (_lineWidth + _fontCharacterSize.height);
	double topInset = viewHeightRatio * self.insets.top;
	double spacing = viewHeightRatio * (_lineWidth + _fontCharacterSize.height + _lineSpacing);
	
	CPTPlotRange* xRange = self.plotRange;
	double previousLocation = xRange.locationDouble;
	
	double pointOnGraph = previousLocation + clickPoint.x * xRange.lengthDouble / selfBounds.size.width;
	
	BOOL found = NO;
	NSUInteger idx = 0;
	for(DTXRangePlotViewRange* line in _lines)
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
	else
	{
		[self.delegate plotView:self didClickRangeAtIndex:NSNotFound];
	}
}

@end
