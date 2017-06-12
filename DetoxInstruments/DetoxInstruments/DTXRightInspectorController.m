//
//  DTXRightInspectorController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRightInspectorController.h"
#import "DTXDocument.h"

@interface DTXRightInspectorController ()
{
	__unsafe_unretained IBOutlet NSTextView *_textView;
	NSAttributedString* _recordingDescription;
}

@end

@implementation DTXRightInspectorController

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[_textView setTextContainerInset:NSMakeSize(0, 6)];
	
	if(_recordingDescription == nil)
	{
		DTXRecording* recording = [self.view.window.windowController.document recording];
		if(recording == nil)
		{
			//TODO: Handle
			return;
		}
		
		NSMutableAttributedString* rv = [NSMutableAttributedString new];
		
		NSMutableParagraphStyle* headlineParagraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		headlineParagraph.paragraphSpacing = 6;
		NSDictionary* headlineAttributes = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:10], NSParagraphStyleAttributeName: headlineParagraph};
		
		NSMutableParagraphStyle* bodyParagraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		bodyParagraph.firstLineHeadIndent = 20;
		bodyParagraph.headIndent = 20;
		
		NSDictionary* bodyAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:10], NSParagraphStyleAttributeName: bodyParagraph};
		
		NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
		ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
		
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Recording Info\n", @"") attributes:headlineAttributes]];
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target Name", @""), recording.deviceName] attributes:bodyAttributes]];
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target Model", @""), recording.deviceType] attributes:bodyAttributes]];
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target OS", @""), recording.deviceOS] attributes:bodyAttributes]];

		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:bodyAttributes]];
		
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Start Time", @""), [NSDateFormatter localizedStringFromDate:recording.startTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]] attributes:bodyAttributes]];
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"End Time", @""), [NSDateFormatter localizedStringFromDate:recording.endTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]] attributes:bodyAttributes]];
		[rv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Duration", @""), [ivFormatter stringFromDate:recording.startTimestamp toDate:recording.endTimestamp]] attributes:bodyAttributes]];
		
		_recordingDescription = rv;
	}
		
	[_textView.textStorage setAttributedString:_recordingDescription];
}

@end
