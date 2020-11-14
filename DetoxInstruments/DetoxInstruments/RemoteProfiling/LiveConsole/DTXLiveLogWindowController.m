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

@property (nonatomic, weak) IBOutlet NSButton* nowButton;
@property (nonatomic, weak) IBOutlet NSButton* clearButton;

@end

@implementation DTXLiveLogWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	DTXFilterAccessoryController* filterController = [self.storyboard instantiateControllerWithIdentifier:@"FilterController"];
	filterController.delegate = (id)self.window.contentViewController;
	
	[self.window addTitlebarAccessoryViewController:filterController];
	
	[_nowButton bind:NSValueBinding toObject:self.window.contentViewController withKeyPath:@"nowMode" options:nil];
	
	if(@available(macOS 11.0, *))
	{
		NSImage* image = [NSImage imageWithSystemSymbolName:@"xmark.circle" accessibilityDescription:nil];
		image.size = NSMakeSize(15, 15);
		self.clearButton.image = image;
	}
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	[(DTXLiveLogViewController*)self.window.contentViewController setProfilingTarget:self.profilingTarget];
}

@end
