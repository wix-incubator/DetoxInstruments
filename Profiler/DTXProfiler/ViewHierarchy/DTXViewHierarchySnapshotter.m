//
//  DTXViewHierarchySnapshotter.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/17/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXViewHierarchySnapshotter.h"
#import "AutoCoding.h"
@import ObjectiveC;

@interface CALayer ()

- (void)_renderBackgroundInContext:(struct CGContext *)arg1;
- (void)_renderBorderInContext:(struct CGContext *)arg1;
- (void)_renderSublayersInContext:(struct CGContext *)arg1;
- (void)_renderForegroundInContext:(struct CGContext *)arg1;

@end

#define ENCODE_STRUCT_FIELD(st, fld, name) [aCoder encodeDouble:st.fld forKey:[NSString stringWithFormat:@"%@_%s", name, #fld]]
#define DECODE_STRUCT_FIELD(st, fld, name) st.fld = [aDecoder decodeDoubleForKey:[NSString stringWithFormat:@"%@_%s", name, #fld]]

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
			Method m = class_getInstanceMethod(self.class, NSSelectorFromString(key));
			char* returnType = method_copyReturnType(m);
			dtx_defer {
				free(returnType);
			};
			
			if(obj == DTXSnapshotImage.class)
			{
				NSData* data = [aDecoder decodeObjectForKey:key];
				DTXSnapshotImage* image;
#if TARGET_OS_IPHONE
				image = [UIImage imageWithData:data];
#else
				image = [[NSImage alloc] initWithData:data];
#endif
				[self setValue:image forKey:key];
				
				return;
			}
			else if(obj == NSValue.class && strcmp(returnType, @encode(CATransform3D)) == 0)
			{
				CATransform3D ct3d;
				DECODE_STRUCT_FIELD(ct3d, m11, key);
				DECODE_STRUCT_FIELD(ct3d, m12, key);
				DECODE_STRUCT_FIELD(ct3d, m13, key);
				DECODE_STRUCT_FIELD(ct3d, m14, key);
				DECODE_STRUCT_FIELD(ct3d, m21, key);
				DECODE_STRUCT_FIELD(ct3d, m22, key);
				DECODE_STRUCT_FIELD(ct3d, m23, key);
				DECODE_STRUCT_FIELD(ct3d, m24, key);
				DECODE_STRUCT_FIELD(ct3d, m31, key);
				DECODE_STRUCT_FIELD(ct3d, m32, key);
				DECODE_STRUCT_FIELD(ct3d, m33, key);
				DECODE_STRUCT_FIELD(ct3d, m34, key);
				DECODE_STRUCT_FIELD(ct3d, m41, key);
				DECODE_STRUCT_FIELD(ct3d, m42, key);
				DECODE_STRUCT_FIELD(ct3d, m43, key);
				DECODE_STRUCT_FIELD(ct3d, m44, key);
				[self setValue:[NSValue valueWithCATransform3D:ct3d] forKey:key];
				
				return;
			}
			
			[self setValue:[aDecoder decodeObjectOfClass:obj forKey:key] forKey:key];
		}];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		id value = [self valueForKey:key];
		if(obj == DTXSnapshotImage.class)
		{
			NSData* data;
#if TARGET_OS_IPHONE
			data = UIImagePNGRepresentation([self valueForKey:key]);
#else
			NSImage* image = value;
			
			CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
			NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
			newRep.size = image.size;
			data = [newRep representationUsingType:NSPNGFileType properties:@{}];
			
#endif
			[aCoder encodeObject:data forKey:key];
			
			return;
		}
		else if(obj == NSValue.class && strcmp(((NSValue*)value).objCType, @encode(CATransform3D)) == 0)
		{
			CATransform3D ct3d = [[self valueForKey:key] CATransform3DValue];
			
			ENCODE_STRUCT_FIELD(ct3d, m11, key);
			ENCODE_STRUCT_FIELD(ct3d, m12, key);
			ENCODE_STRUCT_FIELD(ct3d, m13, key);
			ENCODE_STRUCT_FIELD(ct3d, m14, key);
			ENCODE_STRUCT_FIELD(ct3d, m21, key);
			ENCODE_STRUCT_FIELD(ct3d, m22, key);
			ENCODE_STRUCT_FIELD(ct3d, m23, key);
			ENCODE_STRUCT_FIELD(ct3d, m24, key);
			ENCODE_STRUCT_FIELD(ct3d, m31, key);
			ENCODE_STRUCT_FIELD(ct3d, m32, key);
			ENCODE_STRUCT_FIELD(ct3d, m33, key);
			ENCODE_STRUCT_FIELD(ct3d, m34, key);
			ENCODE_STRUCT_FIELD(ct3d, m41, key);
			ENCODE_STRUCT_FIELD(ct3d, m42, key);
			ENCODE_STRUCT_FIELD(ct3d, m43, key);
			ENCODE_STRUCT_FIELD(ct3d, m44, key);
			
			return;
		}
		
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
	if(sublayers)
	{
		
	}
	else
	{
		[layer _renderBackgroundInContext:ctx];
		[layer _renderBorderInContext:ctx];
		
		//		[layer _renderSublayersInContext:ctx];
		
		[layer _renderForegroundInContext:ctx];
	}
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
	[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
//	__DTXRenderLayerAndSubLayers(view.layer, YES, ctx);
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

+ (void)captureViewHierarchySnapshotWithCompletionHandler:(void (^)(DTXAppSnapshot *))completionHandler
{
	NSParameterAssert(completionHandler != nil);
	
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
