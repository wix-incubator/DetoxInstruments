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

@implementation DTXPlotViewLineAnnotation

- (instancetype)init
{
	self = [super init];
	if(self) { self.priority = 10; }
	return self;
}

@end

@implementation DTXPlotViewRangeAnnotation

- (BOOL)isEqual:(DTXPlotViewRangeAnnotation*)object
{
	if(object.position != self.position || object.end != self.end || [object.color isEqualTo:self.color] == NO || object.opacity != self.opacity)
	{
		return NO;
	}
	
	return YES;
}

@end
@implementation DTXPlotViewTextAnnotation

- (instancetype)init
{
	self = [super init];
	if(self) { self.priority = 100; }
	return self;
}

@end

@interface _DTXAnnotationOverlay : NSView

@property (nonatomic, weak) DTXPlotView* containingPlotView;

@end

@implementation _DTXAnnotationOverlay
{
	NSDictionary* _stringDrawingAttributesLarge;
	double _minWidthRequiredLarge;
	double _minHeightRequiredForLarge;
	double _rectDXInsetsLarge;
	double _rectDYInsetsLarge;
	
	NSDictionary* _stringDrawingAttributesSmall;
	double _minWidthRequiredSmall;
	double _rectDXInsetsSmall;
	double _rectDYInsetsSmall;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		style.lineBreakMode = NSLineBreakByTruncatingTail;
		style.alignment = NSTextAlignmentCenter;
		style.allowsDefaultTighteningForTruncation = NO;
		
		_stringDrawingAttributesLarge = @{NSFontAttributeName: [NSFont userFixedPitchFontOfSize:(NSFont.labelFontSize + NSFont.systemFontSize) / 2.0], NSParagraphStyleAttributeName: style};
		CGSize size = [@"A" sizeWithAttributes:_stringDrawingAttributesLarge];
		_minWidthRequiredLarge = 4 * size.width;
		_minHeightRequiredForLarge = size.height + 10;
		_rectDXInsetsLarge = -3;
		_rectDYInsetsLarge = -1.5;
		
		_stringDrawingAttributesSmall = @{NSFontAttributeName: [NSFont userFixedPitchFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]], NSParagraphStyleAttributeName: style};
		_minWidthRequiredSmall = 4 * [@"A" sizeWithAttributes:_stringDrawingAttributesSmall].width;
		_rectDXInsetsSmall = -2.5;
		_rectDYInsetsSmall = -0.0;
	}
	
	return self;
}

- (NSView *)hitTest:(NSPoint)point
{
	return nil;
}

- (BOOL)isFlipped
{
	return _containingPlotView.isFlipped;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	if(_containingPlotView.annotations.count == 0)
	{
		return;
	}
	
	CGRect selfBounds = self.bounds;
	if(CGRectEqualToRect(selfBounds, CGRectZero))
	{
		return;
	}
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	CGContextResetClip(ctx);
	
	CPTPlotRange* xRange = _containingPlotView.plotRange;
	
	CGFloat graphViewRatio = selfBounds.size.width / xRange.lengthDouble;
	CGFloat offset = - graphViewRatio * xRange.locationDouble;
	
	//Somehow the 0.5 pixel offset on 1x screens with antialiasing disabled make it appear better 🤷‍♂️
	double valuePixelOffset = self.window.backingScaleFactor == 1.0 ? 0.5 : 0.0;
	
	for (DTXPlotViewAnnotation * _Nonnull annotation in _containingPlotView.annotations)
	{
		CGFloat position = offset + graphViewRatio * annotation.position;
		
		if(annotation.class == DTXPlotViewLineAnnotation.class)
		{
			position = floor(position);
			
			DTXPlotViewLineAnnotation* line = (DTXPlotViewLineAnnotation*)annotation;
			
			if(position < dirtyRect.origin.x || position > dirtyRect.origin.x + dirtyRect.size.width)
			{
				continue;
			}
			
			position += valuePixelOffset;
			
			CGContextSetLineWidth(ctx, 1);
			CGContextSetAllowsAntialiasing(ctx, NO);
			CGContextSetStrokeColorWithColor(ctx, [line.color colorWithAlphaComponent:line.color.alphaComponent * line.opacity].CGColor);
			CGContextMoveToPoint(ctx, position, dirtyRect.origin.y);
			CGContextAddLineToPoint(ctx, position, dirtyRect.origin.y + dirtyRect.size.height);
			CGContextStrokePath(ctx);
			
			if(line.drawsValue == YES && [_containingPlotView isKindOfClass:DTXScatterPlotView.class])
			{
				DTXScatterPlotView* scatterPlotView = (id)_containingPlotView;
				double maxHeight = (scatterPlotView.heightSynchronizer ? scatterPlotView.heightSynchronizer.maximumPlotHeight : scatterPlotView.maxHeight);
				CGFloat graphHeightViewRatio = (selfBounds.size.height - scatterPlotView.insets.top - scatterPlotView.insets.bottom) / (maxHeight * scatterPlotView.plotHeightMultiplier);
				
				double value = line.value * graphHeightViewRatio + __DTXBottomInset(scatterPlotView.insets, scatterPlotView.isFlipped);
				
				CGContextSetAllowsAntialiasing(ctx, YES);
				CGContextSetFillColorWithColor(ctx, line.valueColor.CGColor);
				CGContextSetLineWidth(ctx, 1.5);
				NSBezierPath* elipse = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position - __DTXPlotViewAnnotationValueWidth / 2, value - __DTXPlotViewAnnotationValueWidth / 2, __DTXPlotViewAnnotationValueWidth, __DTXPlotViewAnnotationValueWidth)];
				[elipse fill];
				[elipse stroke];
			}
		}
		else if(annotation.class == DTXPlotViewTextAnnotation.class)
		{
			DTXPlotViewTextAnnotation* textAnnotation = (id)annotation;
			
			if(textAnnotation.text.length == 0)
			{
				continue;
			}
			
			double value = selfBounds.size.height / 2;
			if([_containingPlotView isKindOfClass:DTXScatterPlotView.class])
			{
				DTXScatterPlotView* scatterPlotView = (id)_containingPlotView;
				value = 0;
				[scatterPlotView indexOfPointAtViewPosition:position positionInPlot:NULL valueAtPlotPosition:&value];
				
				double maxHeight = (scatterPlotView.heightSynchronizer ? scatterPlotView.heightSynchronizer.maximumPlotHeight : scatterPlotView.maxHeight);
				CGFloat graphHeightViewRatio = (selfBounds.size.height - scatterPlotView.insets.top - scatterPlotView.insets.bottom) / (maxHeight * scatterPlotView.plotHeightMultiplier);
				value = value * graphHeightViewRatio + __DTXBottomInset(scatterPlotView.insets, scatterPlotView.isFlipped);
			}
			
			position = floor(position);
			
			CGContextSaveGState(ctx);
			CGContextSetLineWidth(ctx, 1.5);
			CGContextSetAllowsAntialiasing(ctx, YES);
			
			NSColor* textColor = self.effectiveAppearance.isDarkAppearance ? NSColor.textColor : textAnnotation.color;
			
			NSDictionary* usedAttributes;
			double minWidth;
			double dx, dy;
			if(self.bounds.size.height >= _minHeightRequiredForLarge)
			{
				usedAttributes = _stringDrawingAttributesLarge;
				minWidth = _minWidthRequiredLarge;
				dx = _rectDXInsetsLarge;
				dy = _rectDYInsetsLarge;
			}
			else
			{
				usedAttributes = _stringDrawingAttributesSmall;
				minWidth = _minWidthRequiredSmall;
				dx = _rectDXInsetsSmall;
				dy = _rectDYInsetsSmall;
			}
			
			NSMutableDictionary* attrs = usedAttributes.mutableCopy;
			attrs[NSForegroundColorAttributeName] = textColor;
			NSAttributedString* attr = [[NSAttributedString alloc] initWithString:textAnnotation.text attributes:attrs];
			
			CGRect boundingRect = CGRectInset([attr boundingRectWithSize:selfBounds.size options:0], dx, dy);
			CGRect drawRect = (CGRect){position + __DTXPlotViewAnnotationValueWidth, value, boundingRect.size};
			
			if(drawRect.origin.y < 5.0 + _containingPlotView.insets.bottom)
			{
				drawRect.origin.y = 5.0 + _containingPlotView.insets.bottom;
			}
			else if(drawRect.origin.y + drawRect.size.height > selfBounds.size.height - 5.0)
			{
				drawRect.origin.y = selfBounds.size.height - 5.0 - drawRect.size.height;
			}
			
			if(drawRect.origin.x + MAX(minWidth, drawRect.size.width) > selfBounds.size.width - 5.0)
			{
				drawRect.origin.x = position - __DTXPlotViewAnnotationValueWidth - drawRect.size.width;
			}
			
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathAddRoundedRect(path, NULL, drawRect, 4, 4);
			
			NSColor* fillColor = self.effectiveAppearance.isDarkAppearance ? textAnnotation.valueColor : NSColor.textBackgroundColor;
			CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
			CGContextAddPath(ctx, path);
			CGContextClip(ctx);
			CGContextFillRect(ctx, drawRect);
			CGContextResetClip(ctx);
			
			NSColor* strokeColor = self.effectiveAppearance.isDarkAppearance ? NSColor.textColor : textAnnotation.color;
			CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);
			CGContextAddPath(ctx, path);
			CGContextStrokePath(ctx);
			
			CGPathRelease(path);
			
			[attr drawInRect:drawRect];
			
			CGContextSetStrokeColorWithColor(ctx, textAnnotation.color.CGColor);
			CGContextSetFillColorWithColor(ctx, textAnnotation.valueColor.CGColor);
			CGContextSetLineWidth(ctx, 1.5);
			NSBezierPath* elipse = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position - __DTXPlotViewAnnotationValueWidth / 2, value - __DTXPlotViewAnnotationValueWidth / 2, __DTXPlotViewAnnotationValueWidth, __DTXPlotViewAnnotationValueWidth)];
			[elipse fill];
			[elipse stroke];
			
			CGContextRestoreGState(ctx);
		}
	}
}

@end

@interface DTXPlotView () <NSGestureRecognizerDelegate> @end

@implementation DTXPlotView
{
	BOOL _mouseClicked;
	NSClickGestureRecognizer* _cgr;
	
	BOOL _hasRangeAnnotations;
	
	_DTXAnnotationOverlay* _overlay;
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
	
		_overlay = [_DTXAnnotationOverlay new];
		_overlay.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
		_overlay.containingPlotView = self;
		_overlay.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self addSubview:_overlay];
		
		[NSLayoutConstraint activateConstraints:@[
												  [_overlay.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
												  [_overlay.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
												  [_overlay.topAnchor constraintEqualToAnchor:self.topAnchor],
												  [_overlay.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
												  ]];
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
	
	NSMutableArray<DTXPlotViewAnnotation *>* newAnnotations = annotations.mutableCopy;
	[newAnnotations sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES]]];
	
	for (DTXPlotViewAnnotation* annotation in newAnnotations)
	{
		if([annotation isKindOfClass:DTXPlotViewRangeAnnotation.class])
		{
			_hasRangeAnnotations = YES;
		}
	}
	
	NSArray* old = [_annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class == %@", DTXPlotViewRangeAnnotation.class]];
	if(old.count == 0)
	{
		old = nil;
	}
	NSArray* new = [newAnnotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class == %@", DTXPlotViewRangeAnnotation.class]];
	if(new.count == 0)
	{
		new = nil;
	}
	
	_annotations = newAnnotations;
	[_overlay setNeedsDisplay:YES];
	
	if(old != new && [old isEqualToArray:new] == NO)
	{
		[self setNeedsDisplay:YES];
	}
}

- (void)setNeedsDisplay:(BOOL)needsDisplay
{
	[super setNeedsDisplay:needsDisplay];
	
	if(needsDisplay)
	{
		[_overlay setNeedsDisplay:YES];
	}
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
