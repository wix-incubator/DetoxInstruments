//
//  DTXPlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotView-Private.h"
#import "NSAppearance+UIAdditions.h"
#import "DTXScatterPlotView-Private.h"
@import QuartzCore;

static const CGFloat __DTXPlotViewAnnotationValueWidth = 7.0;

@implementation _DTXDrawingZone

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> type: %@ start: %.5f next: %p", self.className, self, @(_drawingType), _start, _nextZone];
}

@end

@implementation DTXPlotViewAnnotation

- (instancetype)init
{
	self = [super init];
	if(self) { _opacity = 1.0; _color = NSColor.textColor; }
	return self;
}

@end

@implementation DTXPlotViewLineAnnotation @end
@implementation DTXPlotViewRangeAnnotation @end

@interface DTXPlotView () <NSGestureRecognizerDelegate> @end

@implementation DTXPlotView
{
	BOOL _mouseClicked;
	NSClickGestureRecognizer* _cgr;
	
	BOOL _hasRangeAnnotations;
}

@synthesize flipped=_flipped;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		_cgr = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_clicked:)];
		_cgr.delegate = self;
		[self addGestureRecognizer:_cgr];
		
		[self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
		[self setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
		
		_minimumHeight = -1;
	
	}
	return self;
}

- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (void)_clicked:(NSClickGestureRecognizer*)cgr
{
	
}

- (void)setMinimumHeight:(CGFloat)minimumHeight
{
	_minimumHeight = minimumHeight;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)setInsets:(NSEdgeInsets)insets
{
	_insets = insets;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)setGlobalPlotRange:(CPTPlotRange *)globalXRange
{
	_globalPlotRange = globalXRange;
	
	[self setNeedsDisplay:YES];
}

- (void)setPlotRange:(CPTPlotRange *)xRange
{
	[self _setPlotRange:xRange notifyDelegate:NO];
}

- (void)_setPlotRange:(CPTPlotRange *)xRange notifyDelegate:(BOOL)notify
{
	_plotRange = xRange;
	
	[self setNeedsDisplay:YES];
	
	if(notify)
	{
		[self.delegate plotViewDidChangePlotRange:self];
	}
}

- (BOOL)_hasRangeAnnotations
{
	return _hasRangeAnnotations;
}

- (void)setAnnotations:(NSArray<DTXPlotViewAnnotation *> *)annotations
{
	_hasRangeAnnotations = NO;
	
	_annotations = annotations;
	
	for (DTXPlotViewAnnotation* annotation in annotations)
	{
		if([annotation isKindOfClass:DTXPlotViewRangeAnnotation.class])
		{
			_hasRangeAnnotations = YES;
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)reloadData
{
	if(self.dataSource == nil)
	{
		return;
	}
	
	_isDataLoaded = YES;
	
	[self setNeedsDisplay:YES];
}

- (void)setDataSource:(id<DTXPlotViewDataSource>)dataSource
{
	_dataSource = dataSource;
	
	if(_isDataLoaded)
	{
		[self reloadData];
	}
}

- (void)_scrollPlorRangeWithDelta:(double)delta
{
	if(delta == 0)
	{
		return;
	}
	
	CPTMutablePlotRange* xRange = [self.plotRange mutableCopy];
	CGFloat selfWidth = self.bounds.size.width;
	
	double previousLocation = xRange.locationDouble;
	
	double maxLocation = self.globalPlotRange.lengthDouble - xRange.lengthDouble;
	
	xRange.locationDouble = MIN(maxLocation, MAX(0, xRange.locationDouble - xRange.lengthDouble * delta / selfWidth));
	
	if(xRange.locationDouble != previousLocation)
	{
		[self _setPlotRange:xRange notifyDelegate:YES];
	}
}

- (void)scalePlotRange:(double)scale atPoint:(CGPoint)point
{
	if(scale <= 1.e-6)
	{
		return;
	}
	
	CPTMutablePlotRange* xRange = [self.plotRange mutableCopy];
	
	CGFloat selfWidth = self.bounds.size.width;
	
	double previousLocation = xRange.locationDouble;
	double previousLength = xRange.lengthDouble;
	
	double pointOnGraph = previousLocation + point.x * xRange.lengthDouble / selfWidth;
	
	xRange.lengthDouble = MIN(self.globalPlotRange.lengthDouble, xRange.lengthDouble / scale);
	
	double newLocationX = 0;
	double oldFirstLengthX = pointOnGraph - xRange.minLimitDouble;
	double newFirstLengthX = oldFirstLengthX / scale;
	newLocationX = pointOnGraph - newFirstLengthX;
	
	double maxLocation = self.globalPlotRange.lengthDouble - xRange.lengthDouble;
	xRange.locationDouble = MIN(maxLocation, MAX(0, newLocationX));
	
	if(xRange.locationDouble != previousLocation || xRange.lengthDouble != previousLength)
	{
		[self _setPlotRange:xRange notifyDelegate:YES];
	}
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	if([key isEqualToString:@"plotRange"])
	{
		return [CABasicAnimation animation];
	}
	
	return [super defaultAnimationForKey:key];
}

-(BOOL)acceptsFirstMouse:(nullable NSEvent *)theEvent
{
	return YES;
}

- (void)touchesBeganWithEvent:(NSEvent *)event
{
	_mouseClicked = YES;
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
	CGPoint now = [event.allTouches.anyObject locationInView:self];
	CGPoint prev = [event.allTouches.anyObject previousLocationInView:self];
	
	[self _scrollPlorRangeWithDelta:now.x - prev.x];
}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
	_mouseClicked = NO;
}

- (void)touchesCancelledWithEvent:(NSEvent *)event
{
	_mouseClicked = NO;
}

- (void)mouseDown:(NSEvent *)event
{
	_mouseClicked = YES;
	
	[NSCursor.closedHandCursor push];
}

- (void)mouseDragged:(NSEvent *)event
{
	if(_mouseClicked == NO)
	{
		return;
	}
	
	[self _scrollPlorRangeWithDelta:event.deltaX];
}

- (void)mouseUp:(NSEvent *)event
{
	[NSCursor.closedHandCursor pop];
	
	_mouseClicked = NO;
}

-(void)scrollWheel:(nonnull NSEvent *)event
{
	if(fabs(event.scrollingDeltaY) > fabs(event.scrollingDeltaX))
	{
		[self.nextResponder scrollWheel:event];
		return;
	}
	
	[self _scrollPlorRangeWithDelta:event.scrollingDeltaX];
}

-(void)magnifyWithEvent:(nonnull NSEvent *)event
{
	CGFloat scale = event.magnification + CPTFloat(1.0);
	CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
	
	[self scalePlotRange:scale atPoint:point];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if(self.annotations.count == 0)
	{
		return;
	}
	
	CGRect selfBounds = self.bounds;
	if(CGRectEqualToRect(selfBounds, CGRectZero))
	{
		return;
	}
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextSetLineWidth(ctx, 1);
	CGContextSetAllowsAntialiasing(ctx, self.window.backingScaleFactor > 1.0);
	
	CPTPlotRange* xRange = self.plotRange;
	
	CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
	CGFloat offset = - graphViewRatio * xRange.locationDouble;
	
	for (DTXPlotViewAnnotation * _Nonnull annotation in self.annotations)
	{
		if(annotation.class == DTXPlotViewLineAnnotation.class)
		{
			DTXPlotViewLineAnnotation* line = (DTXPlotViewLineAnnotation*)annotation;
			CGFloat position = floor(offset + graphViewRatio * line.position);
			
			if(position < dirtyRect.origin.x || position > dirtyRect.origin.x + dirtyRect.size.width)
			{
				continue;
			}
			
			CGContextSetStrokeColorWithColor(ctx, [line.color colorWithAlphaComponent:line.color.alphaComponent * line.opacity].CGColor);
			CGContextMoveToPoint(ctx, position, dirtyRect.origin.y);
			CGContextAddLineToPoint(ctx, position, dirtyRect.origin.y + dirtyRect.size.height);
			CGContextStrokePath(ctx);
			
			if(line.drawsValue && [self isKindOfClass:DTXScatterPlotView.class])
			{
				DTXScatterPlotView* scatterPlotView = (id)self;
				CGFloat graphHeightViewRatio = (selfBounds.size.height - scatterPlotView.insets.top - scatterPlotView.insets.bottom) / (scatterPlotView.maxHeight * scatterPlotView.plotHeightMultiplier);
				
				double value = line.value * graphHeightViewRatio;
				
				NSLog(@"value: %@ max: %@", @(line.value), @(scatterPlotView.maxHeight));
				
				CGContextSetAllowsAntialiasing(ctx, YES);
				CGContextSetFillColorWithColor(ctx, line.valueColor.CGColor);
				CGContextSetLineWidth(ctx, 1.5);
				NSBezierPath* elipse = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position - __DTXPlotViewAnnotationValueWidth / 2, value - __DTXPlotViewAnnotationValueWidth / 2, __DTXPlotViewAnnotationValueWidth, __DTXPlotViewAnnotationValueWidth)];
				[elipse fill];
				[elipse stroke];
			}
		}
	}
	
//	[self.annotations enumerateObjectsUsingBlock:^(DTXPlotViewAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
//		NSView* view = _annotationViews[idx];
//
//		CPTPlotRange* xRange = self.plotRange;
//
//		CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
//		CGFloat offset = - graphViewRatio * xRange.locationDouble;
//
//		if(annotation.class == DTXPlotViewLineAnnotation.class)
//		{
//			DTXPlotViewLineAnnotation* line = (DTXPlotViewLineAnnotation*)annotation;
//			CGFloat position = floor(offset + graphViewRatio * line.position);
//
//			if(position < selfBounds.origin.x || position > selfBounds.origin.x + selfBounds.size.width)
//			{
//				view.hidden = YES;
//			}
//			else
//			{
//				view.hidden = NO;
//				view.frame = CGRectMake(position, 0, 1, selfBounds.size.height);
//			}
//		}
//		else if(annotation.class == DTXPlotViewRangeAnnotation.class)
//		{
//			DTXPlotViewRangeAnnotation* range = (DTXPlotViewRangeAnnotation*)annotation;
//
//			CGRect innerBounds = selfBounds;// [self.enclosingScrollView convertRect:selfBounds fromView:self];
//
//			CGFloat start = MAX(innerBounds.origin.x, innerBounds.origin.x + floor(range.start == DBL_MIN ? 0 : offset + graphViewRatio * range.start));
//			CGFloat end = MIN(innerBounds.origin.x + innerBounds.size.width, innerBounds.origin.x + ceil(range.end == DBL_MAX ? innerBounds.size.width : offset + graphViewRatio * range.end));
//
//			if(end < innerBounds.origin.x || start > innerBounds.origin.x + innerBounds.size.width)
//			{
//				if(view.isHidden == NO)
//				{
//					view.hidden = YES;
//				}
//			}
//			else
//			{
//				view.hidden = NO;
//				view.frame = CGRectMake(start, 0, end - start, selfBounds.size.height);
//			}
//		}
//	}];
}

@end
