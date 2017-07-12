//
//  DTXLineLayer.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXLineLayer.h"

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
	
	CGContextSetStrokeColorWithColor(context, _lineColor.CGColor);
	CGContextSetFillColorWithColor(context, _lineColor.CGColor);
	CGContextMoveToPoint(context, self.bounds.size.width / 2.0, 0);    // This sets up the start point
	CGContextAddLineToPoint(context, self.bounds.size.width / 2.0, self.bounds.size.height);
	CGContextStrokePath(context);
	
	CGContextSetLineWidth(context, 1.2);
	
	[self.dataPoints enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGFloat _dataPoint = obj.doubleValue;
		
		CGContextSetFillColorWithColor(context, _pointColors[idx].CGColor);
		
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

- (void)setLineColor:(NSColor*)lineColor
{
	_lineColor = lineColor;
	
	[self setNeedsDisplay];
}

@end
