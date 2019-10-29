//
//  DTXExpandedPreviewWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/5/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXExpandedPreviewWindowController : NSWindowController

@property (nonatomic, strong, readonly) NSView* contentView;

@property (nonatomic, strong, readonly) NSView* toolbarView;
@property (nonatomic, strong, readonly) NSButton* openButton;
@property (nonatomic, strong, readonly) NSButton* saveButton;
@property (nonatomic, strong, readonly) NSButton* shareButton;
@property (nonatomic, copy) NSString* windowTitle;

@property (nonatomic, strong) id closeTarget;
@property (nonatomic) SEL action;

- (void)animateAppearance:(BOOL)animated;
- (void)appearanceAnimationDidEnd;
- (void)disappearanceAnimationWillStart;
- (void)animateDisappearance;

@end
