//
//  DTXViewHierarchySnapshotter.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/17/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#if TARGET_OS_IPHONE
#define DTX_HAS_SNAPSHOTTER 1
#import <UIKit/UIKit.h>
#define DTXSnapshotImage UIImage
#define DTXSnapshotEdgeInsets UIEdgeInsets
#define DTXSnapshotColor UIColor
#define dtx_snapshot_property_modifier readwrite
#else
#define DTX_HAS_SNAPSHOTTER 0
#import <AppKit/AppKit.h>
#define DTXSnapshotImage NSImage
#define DTXSnapshotEdgeInsets NSEdgeInsets
#define DTXSnapshotColor NSColor
#define dtx_snapshot_property_modifier readonly
#endif

@interface DTXViewSnapshot : NSObject <NSSecureCoding>

#if ! DTX_HAS_SNAPSHOTTER
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
#endif

@property (nonatomic, assign, dtx_snapshot_property_modifier) uintptr_t ptr;
@property (nonatomic, strong, dtx_snapshot_property_modifier) NSString* objectClass;
@property (nonatomic, strong, dtx_snapshot_property_modifier) NSString* layerClass;
@property (nonatomic, copy,   dtx_snapshot_property_modifier) NSString* description;
@property (nonatomic, copy,   dtx_snapshot_property_modifier) NSString* recursiveDescription;

@property (nonatomic, assign, dtx_snapshot_property_modifier) NSInteger tag;
@property (nonatomic, assign, dtx_snapshot_property_modifier) BOOL userInteractionEnabled;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CGRect bounds;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CGRect frame;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CGPoint center;
@property (nonatomic, assign, dtx_snapshot_property_modifier) DTXSnapshotEdgeInsets layoutMargins;
@property (nonatomic, assign, dtx_snapshot_property_modifier) DTXSnapshotEdgeInsets safeAreaInsets;
@property (nonatomic, copy,   dtx_snapshot_property_modifier) DTXSnapshotColor* backgroundColor;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CGFloat alpha;
@property (nonatomic, assign, dtx_snapshot_property_modifier) BOOL hidden;
@property (nonatomic, copy,   dtx_snapshot_property_modifier) DTXSnapshotColor* tintColor;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CGAffineTransform transform;
@property (nonatomic, assign, dtx_snapshot_property_modifier) CATransform3D layerTransform;

@property (nonatomic, strong, dtx_snapshot_property_modifier) DTXSnapshotImage* snapshot;
@property (nonatomic, strong, dtx_snapshot_property_modifier) DTXSnapshotImage* snapshotIncludingSubviews;
@property (nonatomic, copy,   dtx_snapshot_property_modifier) NSArray<DTXViewSnapshot*>* subviews;

@end

@interface DTXAppSnapshot : NSObject <NSSecureCoding>

@property (nonatomic, copy,   dtx_snapshot_property_modifier) NSArray<DTXViewSnapshot*>* windows;

@end

#if DTX_HAS_SNAPSHOTTER

@interface DTXViewHierarchySnapshotter : NSObject

+ (void)captureViewHierarchySnapshotWithCompletionHandler:(void(^)(DTXAppSnapshot* snapshot))completionHandler;

@end

#endif
