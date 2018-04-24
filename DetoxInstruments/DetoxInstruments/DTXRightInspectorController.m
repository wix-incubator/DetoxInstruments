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
#import "DTXRecording+UIExtensions.h"

static NSString* const __DTXInspectorTabKey = @"__DTXInspectorTabKey";

@interface DTXRightInspectorController () <DTXSegmentedViewDelegate>
{
	IBOutlet NSTableView* _recordingInfoTableView;
	IBOutlet DTXSegmentedView* _tabSwitcher;
	IBOutlet NSTextField* _nothingLabel;
	DTXInspectorContentTableDataSource* _recordingDescriptionDataSource;
	DTXInspectorContentTableDataSource* _sampleDescriptionDataSource;
	IBOutlet NSMenu* _previewMenu;
}

@end

@implementation DTXRightInspectorController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_tabSwitcher.selectedSegment = [[NSUserDefaults standardUserDefaults] integerForKey:__DTXInspectorTabKey];
	
	[self segmentedView:_tabSwitcher didSelectSegmentAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:__DTXInspectorTabKey]];
	
	_tabSwitcher.delegate = self;
}

- (void)setDocument:(DTXDocument *)document
{
	if(_document)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DTXDocumentStateDidChangeNotification object:_document];
	}
	
	_document = document;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChange:) name:DTXDocumentStateDidChangeNotification object:_document];
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)_documentStateDidChange:(NSNotification*)note
{
	_recordingDescriptionDataSource = nil;
	
	if(self.document.recording == nil)
	{
		return;
	}
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)setMoreInfoDataProvider:(DTXInspectorDataProvider *)moreInfoDataProvider
{
	_moreInfoDataProvider = moreInfoDataProvider;
	
	DTXInstrumentsWindowController* controller = self.view.window.windowController;
	if(_moreInfoDataProvider.canCopy)
	{
		controller.handlerForCopy = _moreInfoDataProvider;
	}
	
	_sampleDescriptionDataSource = _moreInfoDataProvider.inspectorTableDataSource;
	if([_tabSwitcher isSelectedForSegment:0])
	{
		_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
		_recordingInfoTableView.hidden = _sampleDescriptionDataSource == nil;
	}
}

static NSString* __DTXStringFromBoolean(BOOL b)
{
	return b ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @"");
}

- (void)_prepareRecordingDescriptionIfNeeded
{
	if(_recordingDescriptionDataSource != nil)
	{
		return;
	}
	
	if(self.document.documentState <= DTXDocumentStateLiveRecording)
	{
		return;
	}
	
	DTXRecording* recording = [self.document recording];
	DTXProfilingConfiguration* configuration;
	if(recording.profilingConfiguration)
	{
		configuration = recording.dtx_profilingConfiguration;
	}
	
	_recordingDescriptionDataSource = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* recordingInfo = [DTXInspectorContent new];
	recordingInfo.title = NSLocalizedString(@"Recording Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"App Name", @"") description:recording.appName]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Process Identifier", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(recording.processIdentifier)]]];
	if(recording.hasReactNative)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"React Native", @"") description:NSLocalizedString(@"Yes", @"")]];
	}
	
	[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
	
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
	
	if(configuration)
	{
		DTXInspectorContent* recordingConfiguration = [DTXInspectorContent new];
		recordingConfiguration.title = NSLocalizedString(@"Recording Configuration", @"");
		
		content = [NSMutableArray new];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Sampling Interval", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(configuration.samplingInterval)]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Network", @"") description:__DTXStringFromBoolean(configuration.recordNetwork)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Localhost", @"") description:__DTXStringFromBoolean(configuration.recordLocalhostNetwork)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Thread Information", @"") description:__DTXStringFromBoolean(configuration.recordThreadInformation)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Collect Stack Traces", @"") description:__DTXStringFromBoolean(configuration.collectStackTraces)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Symbolicate Stack Traces", @"") description:__DTXStringFromBoolean(configuration.symbolicateStackTraces)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Log Output", @"") description:__DTXStringFromBoolean(configuration.recordLogOutput)]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Profile React Native", @"") description:__DTXStringFromBoolean(configuration.profileReactNative)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Collect Java Script Stack Traces", @"") description:__DTXStringFromBoolean(configuration.collectJavaScriptStackTraces)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Symbolicate Java Script Stack Traces", @"") description:__DTXStringFromBoolean(configuration.symbolicateJavaScriptStackTraces)]];
		
		recordingConfiguration.content = content;
		
		_recordingDescriptionDataSource.contentArray = @[recordingInfo, recordingConfiguration];
	}
	else
	{
		_recordingDescriptionDataSource.contentArray = @[recordingInfo];
	}
	
	if([_tabSwitcher isSelectedForSegment:1])
	{
		_recordingDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = YES;
		_recordingInfoTableView.hidden = NO;
	}
}

- (void)selectExtendedDetail
{
	_tabSwitcher.selectedSegment = 0;
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:__DTXInspectorTabKey];
	
	_recordingDescriptionDataSource.managedTableView = nil;
	_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
	_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
	_recordingInfoTableView.hidden = _sampleDescriptionDataSource == nil;
}

- (void)selectProfilingInfo
{
	_tabSwitcher.selectedSegment = 1;
	[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:__DTXInspectorTabKey];
	
	_sampleDescriptionDataSource.managedTableView = nil;
	_recordingDescriptionDataSource.managedTableView = _recordingInfoTableView;
	_nothingLabel.hidden = _recordingDescriptionDataSource != nil;
	_recordingInfoTableView.hidden = NO;
}

- (void)segmentedView:(DTXSegmentedView *)segmentedView didSelectSegmentAtIndex:(NSInteger)index
{
	if(index == 0)
	{
		[self selectExtendedDetail];
	}
	else
	{
		[self selectProfilingInfo];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	if(menuItem.action == @selector(copyFromContext:))
	{
		return _moreInfoDataProvider.canCopy;
	}
	
	if(menuItem.action == @selector(saveAsFromContext:))
	{
		return _moreInfoDataProvider.canSaveAs;
	}
	
	return NO;
}

- (IBAction)copyFromContext:(id)sender
{
	DTXInstrumentsWindowController* controller = self.view.window.windowController;
	[_moreInfoDataProvider copy:sender targetView:controller.targetForCopy];
}

- (IBAction)saveAsFromContext:(id)sender
{
	[_moreInfoDataProvider saveAs:sender inWindow:self.view.window];
}

@end
