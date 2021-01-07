//
//  DTXDisplayPreferencesViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXDisplayPreferencesViewController.h"
#import "CCNPreferencesWindowControllerProtocol.h"
#import "NSAppearance+UIAdditions.h"

@interface DTXDisplayPreferencesViewController () <CCNPreferencesWindowControllerProtocol>
{
	IBOutlet NSButton* _lightAppearanceButton;
	IBOutlet NSButton* _darkAppearanceButton;
	IBOutlet NSButton* _autoAppearanceButton;
	
//	NSURL* _cachedWallpaperURL;
//	NSImage* _cachedWallpaperImage;
}

@end

@implementation DTXDisplayPreferencesViewController

- (NSImage *)preferenceIcon
{
	NSImage* image;
	if(@available(macOS 11.0, *))
	{
		image = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:nil];
	}
	else
	{
		image = [NSImage imageNamed:NSImageNamePreferencesGeneral];
	}
	
	return image;
}

- (NSString *)preferenceIdentifier
{
	return @"General";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"General", @"");
}

- (NSImage*)_redrawingImageWithName:(NSString*)imageName isMixed:(BOOL)mixed userDefaultsKey:(NSString*)userDefaultsKey highlightingValue:(NSInteger)value
{
	NSImage* image = [NSImage imageNamed:imageName];
	NSImage* rv = [NSImage imageWithSize:NSMakeSize(image.size.width + 3, image.size.height + 3) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		if([NSUserDefaults.standardUserDefaults integerForKey:userDefaultsKey] == value)
		{
			NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(dstRect, 2, 2) xRadius:4 yRadius:4];
			path.lineWidth = 4.0;
			[NSColor.controlAccentColor setStroke];
			[path stroke];
		}
		
		NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.5, 1.5, image.size.width, image.size.height)
															 xRadius:5
															 yRadius:5];
		[clipPath setClip];
		
//		NSURL* currentWallpaperURL = [NSWorkspace.sharedWorkspace desktopImageURLForScreen:NSScreen.mainScreen];
//		if([_cachedWallpaperURL isEqualTo:currentWallpaperURL] == NO)
//		{
//			_cachedWallpaperURL = currentWallpaperURL;
//			_cachedWallpaperImage = [[NSImage alloc] initWithContentsOfURL:_cachedWallpaperURL];
//			_cachedWallpaperImage.size = image.size;
//		}
//		[_cachedWallpaperImage drawInRect:CGRectMake(1.5, 1.5, image.size.width, image.size.height)];
		[image drawInRect:CGRectMake(1.5, 1.5, image.size.width, image.size.height)];
		
		if(mixed == NO)
		{
			NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.5 + 4.5, image.size.height - 13.5 + 1.5, 29, 5.5) xRadius:1.5 yRadius:1.5];
			[NSColor.controlAccentColor setFill];
			[path fill];
		}
		else
		{
			[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 1.5 + 4 + 29, image.size.height)] setClip];
			
			NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.5 + 4.5, image.size.height - 13.5 + 1.5, 29, 5.5) xRadius:1.5 yRadius:1.5];
			[NSColor.controlAccentColor setFill];
			[path fill];
			
			[clipPath setClip];
			
			path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.5 + image.size.width - 28.5, image.size.height - 13.5 + 1.5, 30, 5.5) xRadius:1.5 yRadius:1.5];
			[NSColor.controlAccentColor setFill];
			[path fill];
		}
		
		return YES;
	}];
	
	return rv;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_autoAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_auto" isMixed:YES userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:0];
	_lightAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_light" isMixed:NO userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:1];
	_darkAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_dark" isMixed:NO userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:2];
}

- (IBAction)changeAppearance:(NSButton*)sender
{
	[NSUserDefaults.standardUserDefaults setInteger:sender.tag forKey:DTXPreferencesAppearanceKey];
	
	[_autoAppearanceButton.image recache];
	_autoAppearanceButton.highlighted = YES;
	_autoAppearanceButton.highlighted = NO;
	[_lightAppearanceButton.image recache];
	_lightAppearanceButton.highlighted = YES;
	_lightAppearanceButton.highlighted = NO;
	[_darkAppearanceButton.image recache];
	_darkAppearanceButton.highlighted = YES;
	_darkAppearanceButton.highlighted = NO;
}


@end
