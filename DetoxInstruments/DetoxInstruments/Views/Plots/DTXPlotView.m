//
//  DTXPlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotView.h"
@import QuartzCore;

@interface DTXNoAnimationLayer : CALayer @end
@implementation DTXNoAnimationLayer

-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
	return nil;
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
	
	NSArray<CALayer*>* _annotationLayers;
}

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
	[self _updateAnnotationLayers];
	
	if(notify)
	{
		[self.delegate plotViewDidChangePlotRange:self];
	}
}

- (CALayer*)_layerForAnnotation:(DTXPlotViewAnnotation*)annotation
{
	CALayer* layer = DTXNoAnimationLayer.layer;
	layer.backgroundColor = annotation.color.CGColor;
	layer.opacity = annotation.opacity;
	[self.layer addSublayer:layer];
	return layer;
}

- (void)setAnnotations:(NSArray<DTXPlotViewAnnotation *> *)annotations
{
	[_annotationLayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperlayer];
	}];
	
	_annotations = annotations;
	
	NSMutableArray* layers = [NSMutableArray new];
	for (DTXPlotViewAnnotation* annotation in annotations)
	{
		[layers addObject:[self _layerForAnnotation:annotation]];
	}
	
	_annotationLayers = layers;
	
	[self _updateAnnotationLayers];
}

- (void)layout
{
	[super layout];
	
	[self _updateAnnotationLayers];
}

- (void)_updateAnnotationLayers
{
	if(self.annotations.count == 0)
	{
		return;
	}
	
	CGRect selfBounds = self.bounds;
	if(CGRectEqualToRect(selfBounds, CGRectZero))
	{
		return;
	}
	
	[self.annotations enumerateObjectsUsingBlock:^(DTXPlotViewAnnotation * _Nonnull annotation, NSUInteger idx, BOOL * _Nonnull stop) {
		CALayer* layer = _annotationLayers[idx];

		CPTPlotRange* xRange = self.plotRange;
		
		CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
		CGFloat offset = - graphViewRatio * xRange.locationDouble;
		
		if(annotation.class == DTXPlotViewLineAnnotation.class)
		{
			DTXPlotViewLineAnnotation* line = (DTXPlotViewLineAnnotation*)annotation;
			CGFloat position = floor(offset + graphViewRatio * line.position);
			
			if(position < selfBounds.origin.x || position > selfBounds.origin.x + selfBounds.size.width)
			{
				layer.hidden = YES;
			}
			else
			{
				layer.hidden = NO;
				layer.frame = CGRectMake(position, 0, 1, selfBounds.size.height);
			}
		}
		else if(annotation.class == DTXPlotViewRangeAnnotation.class)
		{
			DTXPlotViewRangeAnnotation* range = (DTXPlotViewRangeAnnotation*)annotation;
			CGFloat start = range.start == DBL_MIN ? 0 : offset + graphViewRatio * range.start;
			CGFloat end = range.end == DBL_MAX ? selfBounds.size.width : offset + graphViewRatio * range.end;
			
			if(end < selfBounds.origin.x || start > selfBounds.origin.x + selfBounds.size.width)
			{
				layer.hidden = YES;
			}
			else
			{
				layer.hidden = NO;
				layer.frame = CGRectMake(start, 0, end - start, selfBounds.size.height);
			}
		}
	}];
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

@end
