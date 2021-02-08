//
//  DTXCookiesViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXCookiesViewController.h"

@interface DTXCookiesViewController () @end

@implementation DTXCookiesViewController
{
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
}

@synthesize profilingTarget=_profilingTarget;

- (NSImage *)preferenceIcon
{
	NSImage* image;
	if(@available(macOS 11.0, *))
	{
		image = [NSImage imageWithSystemSymbolName:@"network" accessibilityDescription:nil];
	}
	else
	{
		image = [NSImage imageNamed:NSImageNameUserAccounts];
	}
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"Cookies";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Cookies", @"");
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadCookies];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadCookies];
}

- (IBAction)save:(id)sender
{
	[self.profilingTarget setCookies:self.cookies];
}

- (IBAction)saveDocument:(id)sender
{
	[self save:sender];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	self.cookies = [DTXCookiesEditorViewController cookiesByFillingMissingFieldsOfCookies:self.profilingTarget.cookies];
}

@end
