//
//  DTXLiveLogWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/28/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXLiveLogWindowController.h"
#import "DTXLiveLogViewController.h"
#import "DTXFilterAccessoryController.h"

@interface DTXLiveLogWindowController ()
{
	IBOutlet NSButton* _nowButton;
}

@end

@implementation DTXLiveLogWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	DTXFilterAccessoryController* filterController = [self.storyboard instantiateControllerWithIdentifier:@"FilterController"];
	filterController.delegate = (id)self.window.contentViewController;
	
	[self.window addTitlebarAccessoryViewController:filterController];
	
	[_nowButton bind:NSValueBinding toObject:self.window.contentViewController withKeyPath:@"nowMode" options:nil];
	[self.window.contentViewController addObserver:self forKeyPath:@"nowMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:NULL];
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	[(DTXLiveLogViewController*)self.window.contentViewController setProfilingTarget:self.profilingTarget];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	[self _resetNowModeButtonImage];
}

- (void)_resetNowModeButtonImage
{
	NSString* imageName = [NSString stringWithFormat:@"NowTemplate%@", _nowButton.state == NSControlStateValueOn ? @"On" : @""];
	_nowButton.image = [NSImage imageNamed:imageName];
}

- (void)dealloc
{
	[self.window.contentViewController removeObserver:self forKeyPath:@"nowMode"];
}

@end
