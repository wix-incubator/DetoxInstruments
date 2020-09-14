//
//  _DTXProfilingConfigurationViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/08/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "_DTXProfilingConfigurationViewController.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "CCNPreferencesWindowControllerProtocol.h"

@interface _DTXProfilingConfigurationIntervalToTag : NSValueTransformer @end

@implementation _DTXProfilingConfigurationIntervalToTag

- (nullable id)transformedValue:(nullable id)value
{
	double val = [value doubleValue];
	
	if(val > 2.0)
	{
		return @20000;
	}
	
	if(val < 0.0625)
	{
		return @625;
	}
	
	return @(val * 10000.0);
}

- (nullable id)reverseTransformedValue:(nullable id)value
{
	return @([value doubleValue] / 10000.0);
}

@end

@interface _DTXProfilingConfigurationViewController () <NSControlTextEditingDelegate, NSUserInterfaceValidations, CCNPreferencesWindowControllerProtocol>

@end

@implementation _DTXProfilingConfigurationViewController
{
	IBOutlet NSButton* _helpButton;
	IBOutlet NSView* _containerView;
	IBOutlet NSStackView* _topStackView;
	
	BOOL _lastValidationFailed;
}

- (NSImage *)preferenceIcon
{
	NSImage* image;
	if(@available(macOS 11.0, *))
	{
		image = [NSImage imageWithSystemSymbolName:@"waveform.path.ecg.rectangle" accessibilityDescription:nil];
	}
	else
	{
		image = [NSImage imageNamed:NSImageNameAdvanced];
	}
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"Recording";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Profiling", @"");
}

- (id)timeLimit
{
	NSNumber* rv = [NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_timeLimit"];
	
	if(rv == nil)
	{
		rv = @2;
	}
	
	return rv;
}

- (void)setTimeLimit:(id)timeLimit
{
	if(timeLimit == nil || [timeLimit isKindOfClass:NSNumber.class] == NO)
	{
		return;
	}
	
	[NSUserDefaults.standardUserDefaults setObject:timeLimit forKey:@"DTXSelectedProfilingConfiguration_timeLimit"];
}

- (id)launchProfilingDuration
{
	NSNumber* rv = [NSUserDefaults.standardUserDefaults objectForKey:DTXPreferencesLaunchProfilingDuration];
	
	if(rv == nil)
	{
		rv = @15.0;
	}
	
	return rv;
}

- (void)setLaunchProfilingDuration:(id)launchProfilingDuration
{
	if(launchProfilingDuration == nil || [launchProfilingDuration isKindOfClass:NSNumber.class] == NO)
	{
		return;
	}
	
	[NSUserDefaults.standardUserDefaults setObject:launchProfilingDuration forKey:DTXPreferencesLaunchProfilingDuration];
}

- (BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)inKey error:(out NSError * _Nullable __autoreleasing *)outError
{
	NSScanner* scanner = [NSScanner scannerWithString:*ioValue];
	
	NSInteger result;
	if([scanner scanInteger:&result] == NO || [scanner isAtEnd] == NO)
	{
		_lastValidationFailed = YES;
		
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The value “%@” is not valid", *ioValue], NSLocalizedRecoverySuggestionErrorKey: @"Please provide a valid value."}];
		
		return NO;
	}
	
	_lastValidationFailed = NO;
	
	*ioValue = @(result);
	
	return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (IBAction)_useDefaultConfiguration:(NSButton *)sender
{
	[DTXProfilingConfiguration resetRemoteProfilingDefaults];
	
	[self willChangeValueForKey:@"timeLimit"];
	[self willChangeValueForKey:@"launchProfilingDuration"];
	
	[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DTXSelectedProfilingConfiguration_timeLimit"];
	[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DTXSelectedProfilingConfiguration_timeLimitType"];
	[NSUserDefaults.standardUserDefaults removeObjectForKey:DTXPreferencesLaunchProfilingDuration];
	
	[self didChangeValueForKey:@"timeLimit"];
	[self didChangeValueForKey:@"launchProfilingDuration"];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	[self.view.window makeFirstResponder:self];
	
	return _lastValidationFailed == NO;
}

@end
