//
//  DTXRemoteTargetCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteTargetCellView.h"
#import "NSColor+UIAdditions.h"
#import "DTXDeviceSnapshotManager.h"

@interface DTXRemoteTargetCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title1Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title2Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title3Field;

@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceScreenSnapshotImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSProgressIndicator* progressIndicator;

@end

@implementation DTXRemoteTargetCellView
{
	IBOutlet NSStackView* _buttonsStack;
	IBOutlet NSButton* _manageButton;
	IBOutlet NSButton* _viewHierarchy;
	IBOutlet NSButton* _warningButton;
	
	DTXDeviceSnapshotManager* _deviceSnapshotManager;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_deviceSnapshotManager = [[DTXDeviceSnapshotManager alloc] initWithDeviceImageView:self.deviceImageView snapshotImageView:self.deviceScreenSnapshotImageView];
	[_deviceSnapshotManager clearDevice];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	[_deviceSnapshotManager clearDevice];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	[_buttonsStack.subviews enumerateObjectsUsingBlock:^(__kindof NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.cell.backgroundStyle = backgroundStyle;
	}];
}

- (void)updateWithTarget:(DTXRemoteTarget*)target
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
	
	self.progressIndicator.usesThreadedAnimation = YES;
	
	switch(target.state)
	{
		case DTXRemoteTargetStateDiscovered:
		case DTXRemoteTargetStateResolved:
			self.title1Field.stringValue = @"";
			self.title2Field.stringValue = target.state == DTXRemoteTargetStateDiscovered ? NSLocalizedString(@"Resolving...", @"") : NSLocalizedString(@"Loading...", @"");
			self.title3Field.stringValue = @"";
			[self.progressIndicator startAnimation:nil];
			self.progressIndicator.hidden = NO;
			break;
		case DTXRemoteTargetStateDeviceInfoLoaded:
		{
			self.title1Field.stringValue = target.appName;
			self.title2Field.stringValue = target.deviceName;
			self.title3Field.stringValue = [NSString stringWithFormat:@"iOS %@", [target.deviceOS stringByReplacingOccurrencesOfString:@"Version " withString:@""]];
			[self.progressIndicator stopAnimation:nil];
			self.progressIndicator.hidden = YES;
			
			[_deviceSnapshotManager setMachineName:target.deviceInfo[@"machineName"] resolution:target.deviceInfo[@"deviceResolution"] enclosureColor:target.deviceInfo[@"deviceEnclosureColor"]];
			
			if(target.screenSnapshot)
			{
				[_deviceSnapshotManager setDeviceScreenSnapshot:target.screenSnapshot];
			}
			
		}	break;
		default:
			break;
	}
}

@end
