//
//  DTXRemoteTargetCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteTargetCellView.h"
#import "NSColor+UIAdditions.h"

@interface DTXRemoteTargetCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title1Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title2Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title3Field;

@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceSnapshotImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSProgressIndicator* progressIndicator;

@end

@implementation DTXRemoteTargetCellView
{
	IBOutlet NSStackView* _buttonsStack;
	IBOutlet NSButton* _manageButton;
	IBOutlet NSButton* _viewHierarchy;
	IBOutlet NSButton* _warningButton;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	[_buttonsStack.subviews enumerateObjectsUsingBlock:^(__kindof NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.cell.backgroundStyle = backgroundStyle;
	}];
}

- (void)updateFeatureSetWithTarget:(DTXRemoteTarget*)target
{
	NSString* profilerVersion = target.deviceInfo[@"profilerVersion"];
	
	if(profilerVersion == nil)
	{
		profilerVersion = @"0";
	}

	if([profilerVersion compare:@"0.9.1" options:(NSNumericSearch)] == NSOrderedAscending)
	{
		_manageButton.enabled = NO;
	}
	else
	{
		_manageButton.enabled = YES;
	}
	
	_manageButton.hidden = target.isCompatibleWithInstruments == NO || _manageButton.enabled == NO;
	_viewHierarchy.hidden = YES;
	_warningButton.hidden = target.isCompatibleWithInstruments;
}

@end
