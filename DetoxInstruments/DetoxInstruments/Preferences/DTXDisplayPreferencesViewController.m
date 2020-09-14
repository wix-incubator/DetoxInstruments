//
//  DTXDisplayPreferencesViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/11/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
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

- (NSImage*)_redrawingImageWithName:(NSString*)imageName overlayImageName:(NSString*)overlayImageName userDefaultsKey:(NSString*)userDefaultsKey highlightingValue:(NSInteger)value
{
	NSImage* image = [NSImage imageNamed:imageName];
	NSImage* overlayImage = nil;
	if(overlayImageName.length > 0)
	{
		overlayImage = [NSImage imageNamed:overlayImageName];
	}
	NSImage* rv = [NSImage imageWithSize:NSMakeSize(image.size.width + 3, image.size.height + 3) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		if([NSUserDefaults.standardUserDefaults integerForKey:userDefaultsKey] == value)
		{
			NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(dstRect, 2, 2) xRadius:4 yRadius:4];
			path.lineWidth = 4.0;
			[NSColor.controlAccentColor setStroke];
			[path stroke];
		}
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1.5, 1.5, image.size.width, image.size.height)
															 xRadius:5
															 yRadius:5];
		[path addClip];
		
//		NSURL* currentWallpaperURL = [NSWorkspace.sharedWorkspace desktopImageURLForScreen:NSScreen.mainScreen];
//		if([_cachedWallpaperURL isEqualTo:currentWallpaperURL] == NO)
//		{
//			_cachedWallpaperURL = currentWallpaperURL;
//			_cachedWallpaperImage = [[NSImage alloc] initWithContentsOfURL:_cachedWallpaperURL];
//			_cachedWallpaperImage.size = image.size;
//		}
//		[_cachedWallpaperImage drawInRect:CGRectMake(1.5, 1.5, image.size.width, image.size.height)];
		[image drawInRect:CGRectMake(1.5, 1.5, image.size.width, image.size.height)];
		[overlayImage drawInRect:CGRectMake(1.5, 1.5, overlayImage.size.width, overlayImage.size.height)];
		
		if(overlayImageName.length > 0)
		{
			NSBezierPath* path = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5 + 12, image.size.height - 6 + 1.5, 32, 6)];
			[NSColor.controlAccentColor setFill];
			[path fill];
		}
		else
		{
			NSBezierPath* path = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5 + 12, image.size.height - 6 + 1.5, 21, 6)];
			[NSColor.controlAccentColor setFill];
			[path fill];
			
			path = [NSBezierPath bezierPathWithRect:NSMakeRect(1.5 + 46, image.size.height - 6 + 1.5, 21, 6)];
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
	
	_autoAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_auto"  overlayImageName:nil userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:0];
	_lightAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_dark" overlayImageName:@"pref_window_light" userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:1];
	_darkAppearanceButton.image = [self _redrawingImageWithName:@"pref_appearance_light" overlayImageName:@"pref_window_dark" userDefaultsKey:DTXPreferencesAppearanceKey highlightingValue:2];
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
