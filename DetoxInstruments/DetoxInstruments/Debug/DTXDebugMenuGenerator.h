//
//  DTXDebugMenuGenerator.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/5/18.
//  Copyright © 2018 Wix. All rights reserved.
//

@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface DTXDebugMenuGenerator : NSObject

@property (nonatomic, strong) IBOutlet NSView* view;
@property (nonatomic, strong) IBOutlet NSVisualEffectView* visualEffectView;

@property (nonatomic, strong) IBOutlet NSImageView* firstImageView;
@property (nonatomic, strong) IBOutlet NSTextField* firstImageTextField;

@property (nonatomic, strong) IBOutlet NSImageView* secondImageView;
@property (nonatomic, strong) IBOutlet NSTextField* secondImageTextField;

@property (nonatomic, strong) IBOutlet NSImageView* chevronImageView;

@end

NS_ASSUME_NONNULL_END
