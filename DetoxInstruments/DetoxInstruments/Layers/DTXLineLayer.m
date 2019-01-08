//
//  DTXLineLayer.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXLineLayer.h"
#import "NSColor+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"

@implementation DTXLineLayer

-(instancetype)initWithFrame:(CGRect)newFrame
{
	self = [super initWithFrame:newFrame];
	
	if(self)
	{
		self.needsDisplayOnBoundsChange = NO;
	}
	
	return self;
}

-(void)renderAsVectorInContext:(nonnull CGContextRef)context
{
	if ( self.hidden ) {
		return;
	}
	
	CGContextSetLineWidth(context, 1.0);
	
	CGFloat offset = 0.0;
	CGFloat height = self.bounds.size.height;
	for(NSColor* color in _lineColors)
	{
		CGFloat lineHeight = self.bounds.size.height / _lineColors.count;
		
		CGContextSetStrokeColorWithColor(context, color.CGColor);
		CGContextSetFillColorWithColor(context, color.CGColor);
		CGContextMoveToPoint(context, self.bounds.size.width / 2.0, height - offset);    // This sets up the start point
		CGContextAddLineToPoint(context, self.bounds.size.width / 2.0, height - offset - lineHeight);
		CGContextStrokePath(context);
		
		offset += lineHeight;
	}
	
	CGContextSetLineWidth(context, 1.2);
	
	[self.dataPoints enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGFloat _dataPoint = obj.doubleValue;
		
		if(NSApplication.sharedApplication.effectiveAppearance.isDarkAppearance)
		{
			CGContextSetStrokeColorWithColor(context, NSColor.whiteColor.CGColor);
		}
		else
		{
			CGContextSetStrokeColorWithColor(context, [_pointColors[idx] deeperColorWithAppearance:NSApplication.sharedApplication.effectiveAppearance modifier:0.3].CGColor);
		}
		
		CGContextSetFillColorWithColor(context, [_pointColors[idx] shallowerColorWithAppearance:NSApplication.sharedApplication.effectiveAppearance modifier:0.15].CGColor);
		
		CGRect ellipseRect = CGRectMake(-3 + self.bounds.size.width / 2.0, -3 + _dataPoint, 6, 6);
		CGContextFillEllipseInRect(context, ellipseRect);
		CGContextStrokeEllipseInRect(context, CGRectInset(ellipseRect, -.5, -.5));
	}];
}

- (void)setDataPoints:(NSArray<NSNumber *> *)dataPoints
{
	_dataPoints = dataPoints;
	
	[self setNeedsDisplay];
}

- (void)setPointColors:(NSArray<NSColor *> *)pointColors
{
	_pointColors = pointColors;
	
	[self setNeedsDisplay];
}

- (void)setLineColors:(NSArray<NSColor *> *)lineColors
{
	_lineColors = lineColors;
	
	[self setNeedsDisplay];
}

@end
