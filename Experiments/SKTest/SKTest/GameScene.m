//
//  GameScene.m
//  SKTest
//
//  Created by Leo Natan (Wix) on 12/27/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "GameScene.h"

@interface FuckOff : SKView <SKViewDelegate>

@property (nonatomic) BOOL allowRenderOnce;

@end

@implementation FuckOff

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.delegate = self;
}

- (BOOL)inLiveResize
{
	return NO;
}

- (BOOL)view:(SKView *)view shouldRenderAtTime:(NSTimeInterval)time
{
	if(_allowRenderOnce)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			_allowRenderOnce = NO;
			[self setPaused:YES];
		});
		return YES;
	}
	
	return NO;
}

- (void)setAllowRenderOnce:(BOOL)allowRenderOnce
{
	_allowRenderOnce = allowRenderOnce;
	
	if(_allowRenderOnce)
	{
		[self setPaused:NO];
	}
}

- (void)layout
{
	[self setAllowRenderOnce:YES];
	
	[super layout];
}

@end

@implementation GameScene {
	SKShapeNode* _shapeTest;
	
	NSMutableArray<NSDictionary*>* _points;
	double _length;
	double _maxHeight;
}

- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
	
	[super awakeFromNib];
	
	NSDictionary* pts = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PointsDataset" ofType:@"plist"]];
	NSArray* points = pts[@"points"];
	_points = [points mutableCopy];
	_maxHeight = [[_points valueForKeyPath:@"@max.value"] doubleValue];
	_length = [_points.lastObject[@"position"] doubleValue];
	
	for(NSUInteger idx = 0; idx < 50; idx++)
	{
		[points enumerateObjectsUsingBlock:^(NSDictionary* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			NSDictionary* point = @{@"value": obj[@"value"], @"position": @([obj[@"position"] doubleValue] + _length)};
			[_points addObject:point];
		}];
		
		_length = [_points.lastObject[@"position"] doubleValue];
	}
	
	_shapeTest = [SKShapeNode new];
	
	_shapeTest.antialiased = YES;
	_shapeTest.lineWidth = 1.5;
	_shapeTest.fillColor = SKColor.systemBlueColor;
	
	self.anchorPoint = CGPointMake(0, 0);
	
	_shapeTest.position = CGPointMake(0, 0);
	[self addChild:_shapeTest];
	
	[self _updatePath];
}

- (void)_updatePath
{
	if(self.view == nil)
	{
		return;
	}
	
	double extraScale = self.view.window.backingScaleFactor == 1 ? 2 : 1;
	
	CGFloat graphViewRatio = extraScale * self.size.width / _length;
	CGFloat graphHeightViewRatio = extraScale * self.size.height / (_maxHeight * 1.1);
	
	double x = graphViewRatio * [_points[0][@"position"] doubleValue];
	double y = graphHeightViewRatio * [_points[0][@"value"] doubleValue];
	
	CGMutablePathRef _path = CGPathCreateMutable();
	CGPathMoveToPoint(_path, NULL, x, y);
	for(NSUInteger idx = 1; idx < _points.count; idx++)
	{
		double x = graphViewRatio * [_points[idx][@"position"] doubleValue];
		double y = graphHeightViewRatio * [_points[idx][@"value"] doubleValue];
		
		CGPathAddLineToPoint(_path, NULL, x, y);
	}
	
	_shapeTest.path = _path;
	[_shapeTest setScale:self.view.window.backingScaleFactor == 1 ? 0.5 : 1];
	
	CGPathRelease(_path);
}

-(void)update:(CFTimeInterval)currentTime
{
//	[self _updatePath];
	NSAppearance.currentAppearance = NSApp.appearance;
	_shapeTest.strokeColor = [NSColor.textColor colorWithAlphaComponent:1.0];
}

- (void)didChangeSize:(CGSize)oldSize;
{
	[super didChangeSize:oldSize];
	
	[self _updatePath];
}

@end
