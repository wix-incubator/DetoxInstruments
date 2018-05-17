//
//  DTXViewHierarchySnapshotter.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/17/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXViewHierarchySnapshotter.h"
#import "AutoCoding.h"

@interface CALayer ()

- (void)_renderBackgroundInContext:(struct CGContext *)arg1;
- (void)_renderBorderInContext:(struct CGContext *)arg1;
- (void)_renderSublayersInContext:(struct CGContext *)arg1;
- (void)_renderForegroundInContext:(struct CGContext *)arg1;

@end

@implementation DTXViewSnapshot

@synthesize description=_description, recursiveDescription=_recursiveDescription;

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if(self)
	{
		[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop)
		{
			[self setValue:[aDecoder decodeObjectOfClass:obj forKey:key] forKey:key];
		}];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[aCoder encodeObject:[self valueForKey:key] forKey:key];
	}];
}

@end
@implementation DTXAppSnapshot

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if(self)
	{
		[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop)
		 {
			 [self setValue:[aDecoder decodeObjectOfClass:obj forKey:key] forKey:key];
		 }];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[aCoder encodeObject:[self valueForKey:key] forKey:key];
	}];
}

@end

#if DTX_HAS_SNAPSHOTTER

static void __DTXRenderLayerAndSubLayers(CALayer* layer, BOOL sublayers, CGContextRef ctx)
{
	[layer _renderBackgroundInContext:ctx];
	[layer _renderBorderInContext:ctx];
	if(sublayers)
	{
		[layer _renderSublayersInContext:ctx];
	}
	[layer _renderForegroundInContext:ctx];
}

@implementation DTXViewHierarchySnapshotter

+ (DTXViewSnapshot*)_snapshotView:(UIView*)view
{
	DTXViewSnapshot* viewSnapshot = [DTXViewSnapshot new];
	
	NSArray<NSString*>* copyKeys = @[@"tag", @"userInteractionEnabled", @"bounds", @"frame", @"center", @"layoutMargins", @"safeAreaInsets", @"backgroundColor", @"alpha", @"hidden", @"tintColor", @"transform", @"description", @"recursiveDescription"];
	
	[copyKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[viewSnapshot setValue:[view valueForKey:obj] forKey:obj];
	}];
	
	viewSnapshot.ptr = (uintptr_t)PTR(view);
	viewSnapshot.objectClass = NSStringFromClass(view.class);
	viewSnapshot.layerClass = NSStringFromClass([view.class layerClass]);
	
	viewSnapshot.layerTransform = view.layer.transform;
	
	UIWindow* windowForScreen = [view isKindOfClass:[UIWindow class]] ? (UIWindow*)view : view.window;
	
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, windowForScreen.screen.scale);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	__DTXRenderLayerAndSubLayers(view.layer, NO, ctx);
	viewSnapshot.snapshot = UIGraphicsGetImageFromCurrentImageContext();
//	[UIImagePNGRepresentation(viewSnapshot.snapshot) writeToFile:[NSString stringWithFormat:@"/Users/lnatan/Desktop/Snapshots/%p_%@.png", view, NSStringFromClass(view.class)] atomically:YES];
	UIGraphicsEndImageContext();
	
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, windowForScreen.screen.scale);
	ctx = UIGraphicsGetCurrentContext();
	__DTXRenderLayerAndSubLayers(view.layer, YES, ctx);
	viewSnapshot.snapshotIncludingSubviews = UIGraphicsGetImageFromCurrentImageContext();
//	[UIImagePNGRepresentation(viewSnapshot.snapshotIncludingSubviews) writeToFile:[NSString stringWithFormat:@"/Users/lnatan/Desktop/Snapshots/%p_%@_full.png", view, NSStringFromClass(view.class)] atomically:YES];
	UIGraphicsEndImageContext();
	
	NSMutableArray<DTXViewSnapshot*>* subviews = [NSMutableArray new];
	[view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[subviews addObject:[self _snapshotView:obj]];
	}];
	viewSnapshot.subviews = subviews;
	
	return viewSnapshot;
}

+ (void)createViewHierarchySnapshotWithCompletionHandler:(void (^)(DTXAppSnapshot *))completionHandler
{
	void (^snapshotter)(void) = ^ {
		NSAssert(NSThread.isMainThread, @"Must execute on main thread");
		
		DTXAppSnapshot* appSnapshot = [DTXAppSnapshot new];
		NSMutableArray<DTXViewSnapshot*>* windows = [NSMutableArray new];
		
		[UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[windows addObject:[self _snapshotView:obj]];
		}];
		
		appSnapshot.windows = windows;
		completionHandler(appSnapshot);
	};
	
	if(NSThread.isMainThread == YES)
	{
		snapshotter();
		
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		snapshotter();
	});
}

@end

#endif
