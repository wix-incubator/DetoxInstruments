//
//  DTXPlotView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPlotView-Private.h"
#import "NSAppearance+UIAdditions.h"
#import "DTXScatterPlotView-Private.h"
#import "NSFont+UIAdditions.h"
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

static NSAttributedString* _DTXGetAttributedStringForDrawing(NSString* text, NSColor* textColor, NSString* additionalText, NSColor* additionalTextColor, CGRect bounds, CGFloat x, CGFloat y, CGRect* drawRect, double* minComfortableWidth, double fontSizeToUse)
{
	static double _largestFontSize;
	
	static NSDictionary* _stringDrawingAttributes;
	
	static double _minWidth;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_largestFontSize = [NSFont systemFontSizeForControlSize:NSControlSizeRegular];
		
		NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		style.lineBreakMode = NSLineBreakByWordWrapping;
		style.alignment = NSTextAlignmentCenter;
		style.allowsDefaultTighteningForTruncation = NO;
		
		_stringDrawingAttributes = @{NSParagraphStyleAttributeName: style};
	});

	if(fontSizeToUse == 0)
	{
		fontSizeToUse = _largestFontSize;
	}
	
	NSMutableDictionary* usedAttributes = _stringDrawingAttributes.mutableCopy;
	usedAttributes[NSFontAttributeName] = [NSFont dtx_monospacedSystemFontOfSize:fontSizeToUse weight:fontSizeToUse <= 10 ? NSFontWeightMedium : NSFontWeightRegular];
	
	NSString* textToUse = additionalText == nil ? text : [NSString stringWithFormat:@"%@\n%@", text, additionalText];
	
	NSMutableDictionary* attrs = usedAttributes.mutableCopy;
	attrs[NSForegroundColorAttributeName] = textColor;
	NSMutableAttributedString* attr = [[NSMutableAttributedString alloc] initWithString:textToUse attributes:attrs];
	if(additionalText)
	{
		[attr addAttributes:@{NSForegroundColorAttributeName: additionalTextColor} range:NSMakeRange(attr.length - additionalText.length, additionalText.length)];
	}
	
	CGRect boundingRect = [attr boundingRectWithSize:CGSizeMake(bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
	
	*drawRect = (CGRect){x + __DTXPlotViewAnnotationValueWidth, y, CGSizeMake(boundingRect.size.width + (0.5*fontSizeToUse), boundingRect.size.height)};
	
	if(drawRect->size.height >= bounds.size.height * 0.8)
	{
		return _DTXGetAttributedStringForDrawing(text, textColor, additionalText, additionalTextColor, bounds, x, y, drawRect, minComfortableWidth, fontSizeToUse - 0.5);
	}
	
	_minWidth = MAX(_minWidth, drawRect->size.width);
	*minComfortableWidth = _minWidth;
	
	return attr;
}

@implementation _DTXAnnotationOverlay
{
	
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
	
	DTXPlotRange* range = _containingPlotView.plotRange;
	
	CGFloat graphViewRatio = selfBounds.size.width / range.length;
	CGFloat offset = - graphViewRatio * range.position;
	
	for (DTXPlotViewAnnotation * _Nonnull annotation in _containingPlotView.annotations)
	{
		CGFloat position = offset + graphViewRatio * annotation.position;
		
		if(annotation.class == DTXPlotViewLineAnnotation.class)
		{
			DTXPlotViewLineAnnotation* line = (DTXPlotViewLineAnnotation*)annotation;
			
			if(position < dirtyRect.origin.x || position > dirtyRect.origin.x + dirtyRect.size.width)
			{
				continue;
			}
			
			CGContextSetLineWidth(ctx, 1.0);
			CGContextSetAllowsAntialiasing(ctx, self.window.backingScaleFactor != 1.0);
			CGContextSetStrokeColorWithColor(ctx, [line.color colorWithAlphaComponent:line.color.alphaComponent * line.opacity].CGColor);
			CGContextMoveToPoint(ctx, position, dirtyRect.origin.y);
			CGContextAddLineToPoint(ctx, position, dirtyRect.origin.y + dirtyRect.size.height);
			CGContextStrokePath(ctx);
		}
		else if(annotation.class == DTXPlotViewTextAnnotation.class)
		{
			DTXPlotViewTextAnnotation* textAnnotation = (id)annotation;
			
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
			
			if(textAnnotation.showsValue == YES)
			{
				CGContextSetStrokeColorWithColor(ctx, textAnnotation.color.CGColor);
				CGContextSetFillColorWithColor(ctx, textAnnotation.valueColor.CGColor);
				NSBezierPath* elipse = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(position - __DTXPlotViewAnnotationValueWidth / 2, value - __DTXPlotViewAnnotationValueWidth / 2, __DTXPlotViewAnnotationValueWidth, __DTXPlotViewAnnotationValueWidth)];
				[elipse fill];
				elipse.lineWidth = 1.0;
				[elipse stroke];
			}
			
			if(textAnnotation.showsText == NO || textAnnotation.text.length == 0)
			{
				continue;
			}
			
			CGContextSaveGState(ctx);
			CGContextSetAllowsAntialiasing(ctx, YES);
			
			NSColor* textColor = textAnnotation.textColor;
			NSColor* additionalTextColor = textAnnotation.additionalTextColor;
			
			CGRect drawRect;
			double minWidth;
			NSAttributedString* attr = _DTXGetAttributedStringForDrawing(textAnnotation.text, textColor, textAnnotation.showsAdditionalText ? textAnnotation.additionalText : nil, additionalTextColor, self.bounds, position, value, &drawRect, &minWidth, 0);
			
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
			CGPathAddRoundedRect(path, NULL, drawRect, MIN(drawRect.size.width, 8) / 2, MIN(drawRect.size.height, 8) / 2);
			
			CGContextSetLineWidth(ctx, 1.0);
			
			NSColor* fillColor = textAnnotation.textBackgroundColor;
			CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
			CGContextAddPath(ctx, path);
			CGContextClip(ctx);
			CGContextFillRect(ctx, drawRect);
			CGContextResetClip(ctx);
			
			NSColor* strokeColor = textAnnotation.color;
			CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);
			CGContextAddPath(ctx, path);
			CGContextStrokePath(ctx);
			
			CGPathRelease(path);
			
			double textOffset = self.window.backingScaleFactor != 1.0 ? -0.5 : 0.0;
			[attr drawWithRect:CGRectOffset(drawRect, 0, textOffset) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
			
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

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	
	if(self)
	{
		[self _commonInit];
	}
	
	return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		[self _commonInit];
	}
	return self;
}

- (void)_commonInit
{
	_cgr = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_clicked:)];
	_cgr.allowedTouchTypes = NSTouchTypeMaskDirect;
	_cgr.delegate = self;
	[self addGestureRecognizer:_cgr];
	
	[self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
	[self setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
	
	_minimumHeight = -1;
	_fadesOnRangeAnnotation = YES;
	
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

- (void)setFadesOnRangeAnnotation:(BOOL)fadeOnRangeAnnotation
{
	_fadesOnRangeAnnotation = fadeOnRangeAnnotation;
	
	[self setNeedsDisplay:YES];
}

- (void)setInsets:(NSEdgeInsets)insets
{
	_insets = insets;
	
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay:YES];
}

- (void)invalidateIntrinsicContentSize
{
	[super invalidateIntrinsicContentSize];
	
	if([self.delegate respondsToSelector:@selector(plotViewIntrinsicContentSizeDidChange:)])
	{
		[self.delegate plotViewIntrinsicContentSizeDidChange:self];
	}
}

- (void)setGlobalPlotRange:(DTXPlotRange *)globalRange
{
	_globalPlotRange = globalRange.copy;
	
	[self setNeedsDisplay:YES];
}

- (void)setDataLimitRange:(DTXPlotRange *)dataLimitRange
{
	_dataLimitRange = dataLimitRange.copy;
	
	[self setNeedsDisplay:YES];
}

- (void)setPlotRange:(DTXPlotRange *)range
{
	[self _setPlotRange:range notifyDelegate:NO];
}

- (void)_setPlotRange:(DTXPlotRange *)range notifyDelegate:(BOOL)notify
{
	_plotRange = range.copy;
	
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
	
	_dataLoaded = YES;
	
	[self setNeedsDisplay:YES];
}

- (void)setDataSource:(id<DTXPlotViewDataSource>)dataSource
{
	_dataSource = dataSource;
	
	if(_dataLoaded)
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
	
	DTXMutablePlotRange* range = self.plotRange.mutableCopy;
	CGFloat selfWidth = self.bounds.size.width;
	
	double previousLocation = range.position;
	
	double maxLocation = self.globalPlotRange.length - range.length;
	
	range.position = MIN(maxLocation, MAX(0, range.position - range.length * delta / selfWidth));
	
	if(range.position != previousLocation)
	{
		[self _setPlotRange:range notifyDelegate:YES];
	}
}

- (void)scalePlotRange:(double)scale atPoint:(CGPoint)point
{
	if(scale <= 1.e-6)
	{
		return;
	}
	
	DTXMutablePlotRange* range = self.plotRange.mutableCopy;
	
	CGFloat selfWidth = self.bounds.size.width;
	
	double previousLocation = range.position;
	double previousLength = range.length;
	
	double pointOnGraph = previousLocation + point.x * range.length / selfWidth;
	
	range.length = MIN(self.globalPlotRange.length, range.length / scale);
	
	double newLocationX = 0;
	double oldFirstLengthX = pointOnGraph - range.minLimit;
	double newFirstLengthX = oldFirstLengthX / scale;
	newLocationX = pointOnGraph - newFirstLengthX;
	
	double maxLocation = self.globalPlotRange.length - range.length;
	range.position = MIN(maxLocation, MAX(0, newLocationX));
	
	if(range.position != previousLocation || range.length != previousLength)
	{
		[self _setPlotRange:range notifyDelegate:YES];
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

- (BOOL)acceptsFirstMouse:(nullable NSEvent *)theEvent
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

- (NSPoint)convertPointFromWindow:(NSPoint)point
{
	point = [self convertPoint:point fromView:self.window.contentView];
	point.x = MIN(self.bounds.size.width, MAX(0, point.x));
	
	return CGPointMake(point.x, CGRectGetMidY(self.bounds));
}

- (void)scrollWheel:(nonnull NSEvent *)event
{
	if((event.modifierFlags & NSEventModifierFlagOption) != 0)
	{
		if(event.scrollingDeltaY == 0)
		{
			return;
		}
		
		NSPoint pt = [self convertPointFromWindow:event.locationInWindow];
		
		[self scalePlotRange:1.0 - 0.11 * event.scrollingDeltaY / fabs(event.scrollingDeltaY) atPoint:pt];
		
		return;
	}
	
	if(fabs(event.scrollingDeltaY) > fabs(event.scrollingDeltaX))
	{
		[self.nextResponder scrollWheel:event];
		return;
	}
	
	[self _scrollPlorRangeWithDelta:event.scrollingDeltaX];
}

- (void)magnifyWithEvent:(nonnull NSEvent *)event
{
	CGFloat scale = event.magnification + 1.0;
	CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
	
	[self scalePlotRange:scale atPoint:point];
}

@end
