//
//  PointsView.m
//  DrawTest
//
//  Created by Leo Natan (Wix) on 12/26/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "PointsView.h"

#define NSLog

#define DTX_ADD_POINT(first, path, pt) { if(first == YES) { /*NSLog(@"M %@", @(pt));*/  [path moveToPoint:pt]; first = NO; } else { /* NSLog(@"A %@", @(pt)); */ [path lineToPoint:pt]; } }

@implementation PointsView
{
	NSMutableArray* _points;
	double _length;
	double _maxHeight;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSDictionary* pts = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PointsDataset" ofType:@"plist"]];
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
	
//	for(NSUInteger idx = 0; idx < _points.count; idx++)
//	{
//		NSDictionary* point = @{@"value": @(_maxHeight * (_points.count - (double)idx) / _points.count), @"position": _points[idx][@"position"] };
//		_points[idx] = point;
//	}
//
	
	self.layer.drawsAsynchronously = YES;
}

- (NSSize)intrinsicContentSize
{
	NSTableView* tv = (id)[[[self superview] superview] superview];
	NSInteger row = [tv rowForView:self];
	
	return NSMakeSize(NSViewNoIntrinsicMetric, row == 0 ? 80 : 22);
}

- (void)drawRect:(NSRect)dirtyRect
{
	CFTimeInterval start = CACurrentMediaTime();
	CFTimeInterval startStart = start;
	
	NSUInteger linesDrawn = 0;
	
	CGRect selfBounds = self.bounds;

	CGFloat graphViewRatio = selfBounds.size.width / _length;
	CGFloat graphHeightViewRatio = selfBounds.size.height / (_maxHeight * 1.1);

	NSBezierPath* path = [NSBezierPath bezierPath];
	
	[NSColor.whiteColor setStroke];
	[NSColor.whiteColor setFill];
	
	BOOL first = YES;
//	NSUInteger mergeCount = 0;
	
	double position = graphViewRatio * [_points.firstObject[@"position"] doubleValue];
	double value = graphHeightViewRatio * [_points.firstObject[@"value"] doubleValue];
	
	CGPoint awaiting = CGPointMake(position, value);
	
	DTX_ADD_POINT(first, path, CGPointMake(position, 0));
//	DTX_ADD_POINT(first, path, awaiting);
	linesDrawn+=1;
	
	NSUInteger test = floor(MAX(1.0, _points.count / (selfBounds.size.width * 0.25)));
	NSLog(@"test: %lu", test);
	
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
		
//		if(fabs(awaiting.x - position) >= 0.5 /* || fabs(awaiting.y - value) >= 1.0 */)
//		{
//			linesDrawn++;
//			DTX_ADD_POINT(first, path, awaiting);
//			awaiting = NSMakePoint(position, value);
//		}
//		else
//		{
//			position = (awaiting.x + position) / 2;
//			value = MAX(awaiting.y, value);// (awaiting.y + value) / 2;
//		}
		
		linesDrawn++;
		awaiting = NSMakePoint(position, value);
		DTX_ADD_POINT(first, path, awaiting);
	}
	DTX_ADD_POINT(first, path, awaiting);
	DTX_ADD_POINT(first, path, CGPointMake(awaiting.x, 0));
	linesDrawn+=2;
	
	path.lineWidth = 1.5;
	
	NSGraphicsContext.currentContext.shouldAntialias = YES;
	NSGraphicsContext.currentContext.imageInterpolation = NSImageInterpolationNone;
	
	CFTimeInterval end = CACurrentMediaTime();
	NSLog(@"Took %fs to calc %lu lines", end - start, linesDrawn);
	start = end;
	
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:NSColor.redColor endingColor:NSColor.greenColor];
	[gradient drawInBezierPath:path angle:90];
	
	end = CACurrentMediaTime();
	NSLog(@"Took %fs to render gradient", end - start);
	start = end;

	[path stroke];
	
//	[super drawRect:dirtyRect];

	end = CACurrentMediaTime();
	NSLog(@"Took %fs to stroke path", end - start);
	
	NSLog(@"Took %fs to draw rect", end - startStart);
}

- (BOOL)canDrawConcurrently
{
	return YES;
}

@end
