//
//  DTXRemoteTargetCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteTarget.h"

@interface DTXRemoteTargetCellView : NSTableCellView

@property (nonatomic, strong, readonly) NSTextField* title1Field;
@property (nonatomic, strong, readonly) NSTextField* title2Field;
@property (nonatomic, strong, readonly) NSTextField* title3Field;

@property (nonatomic, strong, readonly) NSImageView* deviceImageView;
@property (nonatomic, strong, readonly) NSImageView* deviceScreenSnapshotImageView;
@property (nonatomic, strong, readonly) NSImageView* deviceSnapshotImageView;
@property (nonatomic, strong, readonly) NSProgressIndicator* progressIndicator;

- (void)updateWithTarget:(DTXRemoteTarget*)target;

@end
