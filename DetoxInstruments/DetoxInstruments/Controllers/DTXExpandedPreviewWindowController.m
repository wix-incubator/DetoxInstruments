//
//  DTXExpandedPreviewWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/5/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXExpandedPreviewWindowController.h"
#import "DTXNoVibrancyView.h"
@import ObjectiveC;
@import Carbon.HIToolbox.Events;

@interface DTXExpandedPreviewWindowController () <NSWindowDelegate>

@property (nonatomic, strong, readwrite) NSButton* openButton;
@property (nonatomic, strong, readwrite) NSButton* saveButton;
@property (nonatomic, strong, readwrite) NSButton* shareButton;
@property (nonatomic, strong, readwrite) NSView* toolbarView;
@property (nonatomic, strong) NSTextField* titleLabel;
@property (nonatomic, strong) NSLayoutConstraint* leftConstraint;

@property (nonatomic, strong, readwrite) NSView* contentView;
@property (nonatomic, strong) NSLayoutConstraint* topConstraint;

@end

@implementation DTXExpandedPreviewWindowController

- (void)windowDidLoad
{
	self.window.styleMask |= ( NSWindowStyleMaskUnifiedTitleAndToolbar);
	
	self.titleLabel = [self.window.contentView viewWithTag:100];
	self.openButton = [self.window.contentView viewWithTag:101];
	self.saveButton = [self.window.contentView viewWithTag:102];
	self.shareButton = [self.window.contentView viewWithTag:103];
	self.toolbarView = self.titleLabel.superview;
	self.leftConstraint = [self.titleLabel.superview.constraints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'left'"]].firstObject;
	self.leftConstraint.active = NO;
	
	self.toolbarView.wantsLayer = YES;
	self.toolbarView.alphaValue = 0.0;
	
	self.contentView = [DTXNoVibrancyView new];
	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentViewController.view addSubview:self.contentView];

	self.topConstraint = [self.contentViewController.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0];

	[NSLayoutConstraint activateConstraints:@[
		[self.contentViewController.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
		[self.contentViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
		[self.contentViewController.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
		self.topConstraint
	]];
	
	[[self.window valueForKeyPath:@"themeFrame.titlebarView"] setAlphaValue:0.0];
}

- (void)setWindowTitle:(NSString *)windowTitle
{
	self.window.title = windowTitle;
	self.titleLabel.stringValue = windowTitle;
}

- (NSString *)windowTitle
{
	return self.titleLabel.stringValue;
}

- (BOOL)windowShouldClose:(NSWindow *)sender
{
	if(self.closeTarget == nil)
	{
		return YES;
	}
	
	void(*objc_msgSend_close)(id, SEL) = (void*)objc_msgSend;
	objc_msgSend_close(self.closeTarget, self.action);
	
	return NO;
}

- (void)appearanceAnimationDidEnd
{
	self.leftConstraint.active = YES;
}

- (void)disappearanceAnimationWillStart
{
	self.leftConstraint.active = NO;
}

- (void)animateAppearance:(BOOL)animated
{
	if(animated)
	{
		self.toolbarView.animator.alphaValue = 1.0;
		self.window.animator.hasShadow = YES;
		self.topConstraint.animator.constant = -37.0;
		
		[[[self.window valueForKeyPath:@"themeFrame.titlebarView"] animator] setAlphaValue:1.0];
	}
	else
	{
		self.toolbarView.alphaValue = 1.0;
		self.window.hasShadow = YES;
		self.topConstraint.constant = -37.0;
		
		[[self.window valueForKeyPath:@"themeFrame.titlebarView"] setAlphaValue:1.0];
	}
}

- (void)animateDisappearance
{
	self.toolbarView.animator.alphaValue = 0.0;
	self.window.animator.hasShadow = NO;
	self.topConstraint.animator.constant = 0.0;
	
	[[[self.window valueForKeyPath:@"themeFrame.titlebarView"] animator] setAlphaValue:0.0];
}

- (void)keyDown:(NSEvent *)event
{
	if(event.keyCode == kVK_Space)
	{
		//To prevent the system beeping.
		return;
	}
	
	[super keyDown:event];
}

- (void)keyUp:(NSEvent *)event
{
	if(event.keyCode == kVK_Space)
	{
		void(*objc_msgSend_close)(id, SEL) = (void*)objc_msgSend;
		objc_msgSend_close(self.closeTarget, self.action);
		return;
	}
	
	[super keyUp:event];
}


@end
