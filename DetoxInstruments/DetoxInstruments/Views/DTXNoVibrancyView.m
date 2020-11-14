//
//  DTXNoVibrancyView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/6/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXNoVibrancyView.h"
@import QuartzCore;

@interface CAFilter : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>
+ (instancetype)filterWithName:(id)arg1;
+ (instancetype)filterWithType:(id)arg1;
+ (id)filterTypes;
- (id)outputKeys;
- (id)inputKeys;
- (id)valueForKey:(id)arg1;
- (void)setValue:(id)arg1 forKey:(id)arg2;
@property(getter=isEnabled) BOOL enabled;
- (BOOL)enabled;
@property(copy) NSString *name;
@property(readonly) NSString *type;
@end

@interface CABackdropLayer : CALayer
{
}

+ (BOOL)CA_automaticallyNotifiesObservers:(Class)arg1;
+ (BOOL)_hasRenderLayerSubclass;
+ (id)defaultValueForKey:(id)arg1;
+ (id)CA_attributes;
+ (void)initialize;
@property BOOL ignoresOffscreenGroups;
@property BOOL disablesOccludedBackdropBlurs;
@property(getter=isInverseMeshed) BOOL inverseMeshed;
@property BOOL windowServerAware;
@property double bleedAmount;
@property double statisticsInterval;
@property(copy) NSString *statisticsType;
@property BOOL ignoresScreenClip;
@property BOOL reducesCaptureBitDepth;
@property BOOL allowsInPlaceFiltering;
@property BOOL captureOnly;
@property double marginWidth;
@property double zoom;
@property struct CGRect backdropRect;
@property double scale;
@property BOOL usesGlobalGroupNamespace;
@property(copy) NSString *groupName;
@property(getter=isEnabled) BOOL enabled;
- (unsigned int)_renderLayerPropertyAnimationFlags:(unsigned int)arg1;
- (_Bool)_renderLayerDefinesProperty:(unsigned int)arg1;
- (void)didChangeValueForKey:(id)arg1;
- (id)statisticsValues;
- (void)layerDidBecomeVisible:(BOOL)arg1;

@end

@implementation DTXNoVibrancyView
{
	CABackdropLayer* _backdrop;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if_unavailable(macOS 11, *)
	{
		_backdrop = [CABackdropLayer new];
		_backdrop.frame = self.bounds;
//		_backdrop.windowServerAware = YES;
		_backdrop.groupName = @"group_name_here";
		auto saturate = [CAFilter filterWithName:@"colorInvert"];
		_backdrop.filters = @[saturate];
		_backdrop.name = @"backdrop";
//		_backdrop.scale = 0.25;
//		_backdrop.bleedAmount = 0.2;
		
		self.wantsLayer = YES;
		[self.layer addSublayer:_backdrop];
		
		self.layerUsesCoreImageFilters = NO;
	}
}

- (void)layout
{
	[super layout];
	
	_backdrop.frame = self.bounds;
}

- (BOOL)allowsVibrancy
{
	return NO;
}

@end

@implementation DTXNoVibrancyTextField

- (BOOL)allowsVibrancy
{
	return NO;
}

@end

@implementation DTXNoVibrancyButton

- (BOOL)allowsVibrancy
{
	return NO;
}

@end
