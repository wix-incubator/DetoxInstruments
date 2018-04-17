//
//  _DTXUserDefaultsOutlineViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/18/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "_DTXUserDefaultsOutlineViewController.h"
@import LNPropertyListEditor;

@interface _DTXUserDefaultsOutlineViewController ()
{
	IBOutlet LNPropertyListEditor* _plistEditor;
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
}
@end

@implementation _DTXUserDefaultsOutlineViewController

- (NSArray<NSButton *> *)actionButtons
{
	return @[_helpButton, _refreshButton];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[_plistEditor.window makeFirstResponder:_plistEditor];
	
	NSRect frame = _plistEditor.window.frame;
	frame.size.width = 850;
	frame.size.height = 550;
	[_plistEditor.window setFrame:frame display:YES animate:YES];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		_plistEditor.propertyList = _plistEditor.propertyList;
	});
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	[super setProfilingTarget:profilingTarget];
	
	[self.profilingTarget loadUserDefaults];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadUserDefaults];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	_plistEditor.propertyList = self.profilingTarget.userDefaults;
}

@end
