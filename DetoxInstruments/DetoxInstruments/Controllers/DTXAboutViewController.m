//
//  DTXAboutViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/25/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXAboutViewController.h"

@interface DTXAboutViewController ()

@property (nonatomic, weak) IBOutlet NSImageView* applicationIconImageView;
@property (nonatomic, weak) IBOutlet NSTextField* applicationTitleTextField;
@property (nonatomic, weak) IBOutlet NSTextField* applicationVersionTextField;
@property (nonatomic, weak) IBOutlet NSTextField* applicationDateTextField;
@property (nonatomic, weak) IBOutlet NSTextField* applicationCopyrightTextField;

@end

@implementation DTXAboutViewController

- (void)viewDidLoad
{
	self.applicationIconImageView.image = [DTXAboutViewController _bestIcon];
	self.applicationTitleTextField.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	self.applicationVersionTextField.stringValue = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"Version", @""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	self.applicationDateTextField.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Built on", @""),[NSDateFormatter localizedStringFromDate:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"DTXBuildDate"] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle]];
	self.applicationCopyrightTextField.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
}

+ (NSImage *)_bestIcon
{
	NSString *resource = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
	if (resource == nil || ![resource isKindOfClass:[NSString class]]) {
		return [NSImage imageNamed:@"NSApplicationImage"];
	}
	
	NSURL *iconURL = [[NSBundle mainBundle] URLForResource:resource withExtension:@"icns"];
	
	// The resource could already be containing the path extension, so try again without the extra extension
	if (iconURL == nil) {
		iconURL = [NSBundle.mainBundle URLForResource:resource withExtension:nil];
	}
	
	NSImage *icon = (iconURL == nil) ? nil : [[NSImage alloc] initWithContentsOfURL:iconURL];
	// Use a default icon if none is defined.
	if (!icon) {
		icon = [[NSWorkspace sharedWorkspace] iconForFileType:NS(kUTTypeApplication)];
	}
	
	return icon;
}

@end
