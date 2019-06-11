//
//  _DTXProfilingConfigurationViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/08/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
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
		return @200;
	}
	
	if(val < 0.25)
	{
		return @25;
	}
	
	return @(val * 100.0);
}

- (nullable id)reverseTransformedValue:(nullable id)value
{
	return @([value doubleValue] / 100.0);
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
	return [NSImage imageNamed:NSImageNameAdvanced];
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
}

- (NSArray<NSButton *> *)actionButtons
{
	return @[_helpButton];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	[self.view.window makeFirstResponder:self];
	
	return _lastValidationFailed == NO;
}

@end
