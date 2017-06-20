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

static NSString* const __DTXInspectorTabKey = @"__DTXInspectorTabKey";

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
	
	[_tabSwitcher setSelected:[[NSUserDefaults standardUserDefaults] integerForKey:__DTXInspectorTabKey] == 0 forSegment:0];
	[_tabSwitcher setSelected:[[NSUserDefaults standardUserDefaults] integerForKey:__DTXInspectorTabKey] == 1 forSegment:1];
	[_tabSwitcher fixIcons];
	
	[self segmentedView:_tabSwitcher didSelectSegmentAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:__DTXInspectorTabKey]];
	
	_tabSwitcher.delegate = self;
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)setMoreInfoDataProvider:(DTXInspectorDataProvider *)moreInfoDataProvider
{
	_moreInfoDataProvider = moreInfoDataProvider;
	
	_sampleDescriptionDataSource = _moreInfoDataProvider.inspectorTableDataSource;
	if([_tabSwitcher isSelectedForSegment:0])
	{
		_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
	}
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
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Target Name", @"") description:recording.deviceName]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Target Model", @"") description:recording.deviceType]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Processor Count", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(recording.deviceProcessorCount)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Physical Memory", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(recording.devicePhysicalMemory)]]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start Time", @"") description:[NSDateFormatter localizedStringFromDate:recording.startTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End Time", @"") description:[NSDateFormatter localizedStringFromDate:recording.endTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]]];
	
	NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
	ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Duration", @"") description:[ivFormatter stringFromDate:recording.startTimestamp toDate:recording.endTimestamp]]];
	
	recordingInfo.content = content;
	
	_recordingDescriptionDataSource.contentArray = @[recordingInfo];
	
	if([_tabSwitcher isSelectedForSegment:1])
	{
		_recordingDescriptionDataSource.managedTableView = _recordingInfoTableView;
	}
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
	
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:__DTXInspectorTabKey];
}

@end
