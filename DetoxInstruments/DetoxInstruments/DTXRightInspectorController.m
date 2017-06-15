//
//  DTXRightInspectorController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

@import WebKit;
#import "DTXRightInspectorController.h"
#import "DTXDocument.h"
#import "DTXInspectorContentTableDataSource.h"
#import "DTXSegmentedView.h"

@interface DTXRightInspectorController () <DTXSegmentedViewDelegate>
{
	IBOutlet NSTableView* _recordingInfoTableView;
	IBOutlet DTXSegmentedView* _tabSwitcher;
	IBOutlet NSTextField* _nothingLabel;
	DTXInspectorContentTableDataSource* _recordingDescriptionDataSource;
	DTXInspectorContentTableDataSource* _sampleDescriptionDataSource;
}

@end

@implementation DTXRightInspectorController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	
	_tabSwitcher.delegate = self;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)_prepareRecordingDescriptionIfNeeded
{
	if(_recordingDescriptionDataSource != nil)
	{
		return;
	}
	
	DTXRecording* recording = [self.view.window.windowController.document recording];
	if(recording == nil)
	{
		return;
	}
	
	_recordingDescriptionDataSource = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* recordingInfo = [DTXInspectorContent new];
	recordingInfo.title = NSLocalizedString(@"Recording Info", @"");
	
	NSMutableString* recordingInfoText = [NSMutableString new];
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target Name", @""), recording.deviceName]];
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target Model", @""), recording.deviceType]];
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Target OS", @""), recording.deviceOS]];
	[recordingInfoText appendString:@"\n"];
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Start Time", @""), [NSDateFormatter localizedStringFromDate:recording.startTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]];
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"End Time", @""), [NSDateFormatter localizedStringFromDate:recording.endTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]];
	
	NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
	ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
	
	[recordingInfoText appendString:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Duration", @""), [ivFormatter stringFromDate:recording.startTimestamp toDate:recording.endTimestamp]]];
	
	recordingInfo.content = recordingInfoText;
	
	_recordingDescriptionDataSource.managedTableView = _recordingInfoTableView;
	_recordingDescriptionDataSource.contentArray = @[recordingInfo];
}

- (void)segmentedView:(DTXSegmentedView *)segmentedView didSelectSegmentAtIndex:(NSInteger)index
{
	if(index == 0)
	{
		_recordingDescriptionDataSource.managedTableView = nil;
		_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
	}
	else
	{
		_sampleDescriptionDataSource.managedTableView = nil;
		_recordingDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = YES;
	}
}

@end
