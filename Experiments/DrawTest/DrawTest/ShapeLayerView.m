//
//  ShapeLayerView.m
//  DrawTest
//
//  Created by Leo Natan (Wix) on 12/29/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "ShapeLayerView.h"
@import QuartzCore;

#define DTX_ADD_POINT(first, path, pt) { if(first == YES) { /*NSLog(@"M %@", @(pt));*/ CGPathMoveToPoint(path, NULL, pt.x, pt.y); first = NO; } else { /* NSLog(@"A %@", @(pt)); */ CGPathAddLineToPoint(path, NULL, pt.x, pt.y); } }

@interface ShapeLineLayer : CAShapeLayer @end

@implementation ShapeLineLayer
{
	NSMutableArray* _points;
	double _length;
	double _maxHeight;
}

- (instancetype)init
{
	self = [super init];
	
	NSDictionary* pts = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PointsDataset" ofType:@"plist"]];
	NSArray* points = pts[@"points"];
	_points = [points mutableCopy];
	_maxHeight = [[_points valueForKeyPath:@"@max.value"] doubleValue];
	_length = [_points.lastObject[@"position"] doubleValue];
	
	for(NSUInteger idx = 0; idx < 100; idx++)
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

- (void)updatePath
{
	CGRect selfBounds = self.bounds;
	
	if(selfBounds.size.width == 0)
	{
		return;
	}
	
	CGFloat graphViewRatio = selfBounds.size.width / _length;
	CGFloat graphHeightViewRatio = selfBounds.size.height / (_maxHeight * 1.1);
	
	BOOL first = YES;
	//	NSUInteger mergeCount = 0;
	
	double position = graphViewRatio * [_points.firstObject[@"position"] doubleValue];
	double value = graphHeightViewRatio * [_points.firstObject[@"value"] doubleValue];
	
	CGPoint awaiting = CGPointMake(position, value);
	
	CGMutablePathRef path = CGPathCreateMutable();
	
	DTX_ADD_POINT(first, path, CGPointMake(position, 0));
	//	DTX_ADD_POINT(first, path, awaiting);
	
	NSUInteger test = ceil(MAX(1.0, _points.count / (selfBounds.size.width)));
	NSLog(@"%u", (unsigned)test);
	
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
	
	self.path = path;
	
	CGPathRelease(path);
}

@end

@implementation ShapeLayerView
{
	ShapeLineLayer* _l;
	NSUInteger _wantsRedrawAfterLiveResize;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_l = [ShapeLineLayer layer];
	_l.lineWidth = 1.5;
	_l.strokeColor = NSColor.whiteColor.CGColor;
	self.wantsLayer = YES;
	[self.layer addSublayer:_l];
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawBeforeViewResize;
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(NSViewNoIntrinsicMetric, 80);
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	_l.frame = self.bounds;
	[_l updatePath];
}

@end
