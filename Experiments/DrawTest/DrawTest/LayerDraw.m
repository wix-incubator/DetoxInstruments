//
//  LayerDraw.m
//  DrawTest
//
//  Created by Leo Natan (Wix) on 12/29/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LayerDraw.h"

#define DTX_ADD_POINT(first, path, pt) { if(first == YES) { /*NSLog(@"M %@", @(pt));*/ CGPathMoveToPoint(path, NULL, pt.x, pt.y); first = NO; } else { /* NSLog(@"A %@", @(pt)); */ CGPathAddLineToPoint(path, NULL, pt.x, pt.y); } }

@interface LineLayer : CALayer @end

@implementation LineLayer
{
	NSMutableArray* _points;
	double _length;
	double _maxHeight;
	
	double _zoom;
}

- (instancetype)init
{
	self = [super init];
	
	NSDictionary* pts = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PointsDataset2" ofType:@"plist"]];
	NSArray* points = pts[@"points"];
	_points = [points mutableCopy];
	_maxHeight = [[_points valueForKeyPath:@"@max.value"] doubleValue];
	_length = [_points.lastObject[@"position"] doubleValue];
	
	for(NSUInteger idx = 0; idx < 0; idx++)
	{
		[points enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSDictionary* point = @{@"value": obj[@"value"], @"position": @([obj[@"position"] doubleValue] + _length)};
			[_points addObject:point];
		}];
		
		_length = [_points.lastObject[@"position"] doubleValue];
	}
	
	self.drawsAsynchronously = YES;
	
	return self;
}

- (id<CAAction>)actionForKey:(NSString *)event
{
	return nil;
}

- (void)drawInContext:(CGContextRef)ctx
{
	CGRect selfBounds = self.bounds;
	
	CGFloat graphViewRatio = selfBounds.size.width / _length;
	CGFloat graphHeightViewRatio = selfBounds.size.height / (_maxHeight * 1.1);
	
	CGContextSetStrokeColorWithColor(ctx, NSColor.whiteColor.CGColor);
	CGContextSetFillColorWithColor(ctx, NSColor.whiteColor.CGColor);
	
	BOOL first = YES;
	//	NSUInteger mergeCount = 0;
	
	double position = graphViewRatio * [_points.firstObject[@"position"] doubleValue];
	double value = graphHeightViewRatio * [_points.firstObject[@"value"] doubleValue];
	
	CGPoint awaiting = CGPointMake(position, value);
	
	CGMutablePathRef path = CGPathCreateMutable();
	
	DTX_ADD_POINT(first, path, CGPointMake(position, 0));
	//	DTX_ADD_POINT(first, path, awaiting);
	
	NSUInteger test = ceil(MIN(80, MAX(1.0, _points.count / (selfBounds.size.width))));
	
	for(NSUInteger idx = 0; idx < _points.count; idx += test)
	{
		double position = 0;
		double value = 0;
		
		NSDictionary* point = [_points objectAtIndex:idx];
		position = graphViewRatio * [point[@"position"] doubleValue];
		
		if(test == 1)
		{
			value = graphHeightViewRatio * [point[@"value"] doubleValue];
		}
		else
		{
			NSUInteger summedPoints = 0;
			for(NSUInteger innerIdx = idx; innerIdx < idx + test && innerIdx + 1 < _points.count; innerIdx++)
			{
				NSDictionary* point = [_points objectAtIndex:innerIdx];
				value = MAX(value, (graphHeightViewRatio * [point[@"value"] doubleValue]));
				//				value += (graphHeightViewRatio * [point[@"value"] doubleValue]);
				summedPoints+=1;
			}
			
			//			if(summedPoints > 0)
			//			{
			//				value /= summedPoints;
			//			}
		}
		
		awaiting = NSMakePoint(position, value);
		DTX_ADD_POINT(first, path, awaiting);
	}
	DTX_ADD_POINT(first, path, awaiting);
	DTX_ADD_POINT(first, path, CGPointMake(awaiting.x, 0));

	CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)@[(__bridge id)NSColor.redColor.CGColor, (__bridge id)NSColor.greenColor.CGColor], NULL);
	
	CGContextAddPath(ctx, path);
	CGContextClip(ctx);

	CGContextDrawLinearGradient(ctx, gradient, CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)), CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)), 0);

	CGGradientRelease(gradient);

	CGContextResetClip(ctx);
	
	CGContextSetLineWidth(ctx, 1.5);
	CGContextAddPath(ctx, path);
	CGContextStrokePath(ctx);
	
	CGPathRelease(path);
}

@end

@implementation LayerDraw
{
	LineLayer* _l;
	NSUInteger _wantsRedrawAfterLiveResize;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_l = [LineLayer layer];
	self.wantsLayer = YES;
	[self.layer addSublayer:_l];
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(NSViewNoIntrinsicMetric, 80);
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	_l.frame = self.bounds;
}

- (void)drawRect:(NSRect)dirtyRect
{
//	if(self.inLiveResize)
//	{
//		_wantsRedrawAfterLiveResize++;
//	}
//
//	if(_wantsRedrawAfterLiveResize % 5 == 0)
//	{
		[_l setNeedsDisplayInRect:dirtyRect];
//	}
}

- (void)viewDidEndLiveResize
{
//	if(_wantsRedrawAfterLiveResize > 0)
//	{
//		[_l setNeedsDisplay];
//		_wantsRedrawAfterLiveResize = 0;
//	}
}

//- (void)setNeedsDisplay:(BOOL)needsDisplay
//{
//	[super setNeedsDisplay:needsDisplay];
//
//	[_l setNeedsDisplay];
//}
//
//- (void)setNeedsDisplayInRect:(NSRect)invalidRect
//{
//	[super setNeedsDisplayInRect:invalidRect];
//
//	[_l setNeedsDisplayInRect:invalidRect];
//}

@end
