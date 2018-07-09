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

- (void)updateFeatureSetWithProfilerVersion:(NSString*)profilerVersion
{
	if(profilerVersion == nil)
	{
		profilerVersion = @"0";
	}

	if([profilerVersion compare:@"0.9.1" options:(NSNumericSearch)] == NSOrderedAscending)
	{
		_manageButton.hidden = !(_manageButton.enabled = NO);
	}
	else
	{
		_manageButton.hidden = !(_manageButton.enabled = YES);
	}
	
	_viewHierarchy.hidden = YES;
}

@end
