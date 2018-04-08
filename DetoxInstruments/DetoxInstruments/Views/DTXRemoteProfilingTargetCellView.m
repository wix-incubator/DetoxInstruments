//
//  DTXRemoteProfilingTargetCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingTargetCellView.h"

@interface DTXRemoteProfilingTargetCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title1Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title2Field;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* title3Field;

@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSImageView* deviceSnapshotImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSProgressIndicator* progressIndicator;

@end

@implementation DTXRemoteProfilingTargetCellView
{
	IBOutlet NSButton* _filesButton;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSImage* folder = [NSImage imageNamed:@"files"];//[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kOpenFolderIcon)];
	folder.size = NSMakeSize(10, 10);
	_filesButton.image = folder;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.title1Field.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor textColor];
	self.title2Field.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor textColor];
	self.title3Field.textColor = backgroundStyle == NSBackgroundStyleDark ? [NSColor selectedTextColor] : [NSColor grayColor];
}

@end
