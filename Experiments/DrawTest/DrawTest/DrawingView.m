//
//  DrawingView.m
//  DrawTest
//
//  Created by Leo Natan (Wix) on 12/23/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "DrawingView.h"
@import QuartzCore;

@interface DrawingView ()

@property (nonatomic, assign) CGFloat zoom;

@end

@interface Line : NSObject

@property (nonatomic) CGFloat start;
@property (nonatomic) CGFloat end;
@property (nonatomic) CGFloat height;
@property (nonatomic, strong) NSColor* color;

@end

@implementation Line @end

@implementation DrawingView
{
	NSDictionary* _info;
	NSArray* _lines;
	NSTimeInterval _totalLength;
	NSUInteger _totalHeightLines;
	
	NSArray* _allColors;
	NSArray* _distinctColors;
	
	NSMapTable* _distinctColorLines;
}

- (void)setZoom:(CGFloat)zoom
{
	_zoom = zoom;
	
	[self setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_info = [NSKeyedUnarchiver unarchiveObjectWithFile:[NSBundle.mainBundle pathForResource:@"Dataset" ofType:@"plist"]];
	_lines = _info[@"lines"];
	_totalLength = 35; //[_info[@"totalLength"] doubleValue];
	_totalHeightLines = [_info[@"totalHeightLines"] unsignedIntegerValue];
	
	_allColors = [_lines valueForKeyPath:@"@unionOfObjects.color"];
	_distinctColors = [_lines valueForKeyPath:@"@distinctUnionOfObjects.color"];
	
	_distinctColorLines = [NSMapTable strongToStrongObjectsMapTable];
	
	[_distinctColors enumerateObjectsUsingBlock:^(NSColor* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableArray* lines = [NSMutableArray new];
		
		[[_lines filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"color == %@", obj]] enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			Line* line = [Line new];
			line.start = [obj[@"start"] doubleValue];
			line.end = [obj[@"end"] doubleValue];
			line.height = [obj[@"height"] doubleValue];
			line.color = obj[@"color"];
			
			[lines addObject:line];
		}];
		
		[_distinctColorLines setObject:lines forKey:obj];
	}];
	
	_zoom = 1.0;
	
	self.layer.drawsAsynchronously = YES;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
			context.duration = 10.0;
			context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			context.allowsImplicitAnimation = YES;
			
			self.animator.zoom = 400.0;
		}];
	});
}

+ (id)defaultAnimationForKey:(NSString *)key
{
	if([key isEqualToString:@"zoom"])
	{
		return [CABasicAnimation animation];
	}
	
	return [super defaultAnimationForKey:key];
}

- (NSSize)intrinsicContentSize
{
	return NSMakeSize(self.bounds.size.width, 10 * _totalHeightLines + 20);
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	CFTimeInterval start = CACurrentMediaTime();
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	CGContextSetLineWidth(ctx, 6.0f);
	
	CGFloat selfWidth = self.bounds.size.width;
	
	CGFloat ratio = selfWidth / _totalLength * _zoom;
	CGFloat offset = - (_totalLength * _zoom - _totalLength) * (selfWidth / _totalLength / 3);
	
	for (NSColor* distinctColor in _distinctColors)
	{
		CGContextSetStrokeColorWithColor(ctx, [distinctColor CGColor]);

		BOOL didAddLine = NO;
		
		for(Line* line in [_distinctColorLines objectForKey:distinctColor])
		{
			NSTimeInterval start = offset + line.start * ratio;
			NSTimeInterval end = offset + line.end * ratio;
			CGFloat height = line.height;

			if(end < 0)
			{
				continue;
			}
			
			if(start > selfWidth)
			{
				continue;
			}
			
			CGContextMoveToPoint(ctx, start, 10.0 * height + 10);
			CGContextAddLineToPoint(ctx, end, 10.0 * height + 10);
			didAddLine = YES;
		}

		if(didAddLine)
		{
			CGContextStrokePath(ctx);
		}
	}
	
//	for(NSDictionary* line in _lines)
//	{
//		NSTimeInterval start = [line[@"start"] doubleValue];
//		NSTimeInterval end = [line[@"end"] doubleValue];
//		CGFloat height = [line[@"height"] doubleValue];
//
//		CGContextSetStrokeColorWithColor(ctx, [line[@"color"] CGColor]);
//
//		CGContextMoveToPoint(ctx, offset + start * ratio, 10.0 * height + 10);
//		CGContextAddLineToPoint(ctx, offset + end * ratio, 10.0 * height + 10);
//
//		CGContextStrokePath(ctx);
//	}
	
	CFTimeInterval end = CACurrentMediaTime();
	NSLog(@"Took %@s to render", @(end - start));
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)canDrawConcurrently
{
	return NO;
}

@end
