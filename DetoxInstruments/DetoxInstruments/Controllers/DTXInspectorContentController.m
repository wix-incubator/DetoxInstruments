//
//  DTXInspectorContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

@import WebKit;
#import "DTXInspectorContentController.h"
#import "DTXRecordingDocument.h"
#import "DTXInspectorContentTableDataSource.h"
#import "DTXSegmentedView.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXFileInspectorContent.h"

static NSString* const DTXInspectorTabKey = @"DTXInspectorTabKey";

@interface DTXInspectorContentController () <DTXSegmentedViewDelegate>
{
	IBOutlet NSTableView* _recordingInfoTableView;
	IBOutlet DTXSegmentedView* _tabSwitcher;
	IBOutlet NSTextField* _nothingLabel;
	DTXInspectorContentTableDataSource* _recordingDescriptionDataSource;
	DTXInspectorContentTableDataSource* _sampleDescriptionDataSource;
	IBOutlet NSMenu* _previewMenu;
}

@end

@implementation DTXInspectorContentController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_tabSwitcher.selectedSegment = [NSUserDefaults.standardUserDefaults integerForKey:DTXInspectorTabKey];
	
	[self segmentedView:_tabSwitcher didSelectSegmentAtIndex:[NSUserDefaults.standardUserDefaults integerForKey:DTXInspectorTabKey]];
	
	_tabSwitcher.delegate = self;
}

- (void)setDocument:(DTXRecordingDocument *)document
{
	if(_document)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:DTXRecordingDocumentStateDidChangeNotification object:_document];
	}
	
	_document = document;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChange:) name:DTXRecordingDocumentStateDidChangeNotification object:_document];
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)_documentStateDidChange:(NSNotification*)note
{
	_recordingDescriptionDataSource = nil;
	
	if(self.document.recordings.count == 0)
	{
		return;
	}
	
	[self _prepareRecordingDescriptionIfNeeded];
}

- (void)setInspectorDataProvider:(DTXInspectorDataProvider *)inspectorDataProvider
{
	_inspectorDataProvider = inspectorDataProvider;
	
	_sampleDescriptionDataSource = _inspectorDataProvider.inspectorTableDataSource;
	if([_tabSwitcher isSelectedForSegment:0])
	{
		_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
		_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
		_recordingInfoTableView.hidden = _sampleDescriptionDataSource == nil;
	}
}

static DTX_ALWAYS_INLINE NSString* __DTXStringFromBoolean(BOOL b)
{
	return b ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @"");
}

- (void)_prepareRecordingDescriptionIfNeeded
{
	if(_recordingDescriptionDataSource != nil)
	{
		return;
	}
	
	if(self.document.documentState <= DTXRecordingDocumentStateLiveRecording)
	{
		return;
	}
	
	DTXRecording* recording = self.document.firstRecording;
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
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Has React Native", @"") description:__DTXStringFromBoolean(YES)]];
	}
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Launch Profiling", @"") description:__DTXStringFromBoolean(recording.isLaunchProfiling)]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Target Name", @"") description:recording.deviceName]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Target Model", @"") description:recording.deviceType]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Processor Count", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(recording.deviceProcessorCount)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Physical Memory", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(recording.devicePhysicalMemory)]]];
	
	[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
	
	if(self.document.recordings.count > 1)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Number of Recordings", @"") description:[NSString stringWithFormat:@"%lu", self.document.recordings.count]]];
	}
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start Time", @"") description:[NSDateFormatter localizedStringFromDate:recording.startTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End Time", @"") description:[NSDateFormatter localizedStringFromDate:self.document.lastRecording.endTimestamp dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterLongStyle]]];
	
	NSDateComponentsFormatter* ivFormatter = [NSDateComponentsFormatter new];
	ivFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Duration", @"") description:[ivFormatter stringFromDate:recording.startTimestamp toDate:self.document.lastRecording.endTimestamp]]];
	
	recordingInfo.content = content;
	
	if(configuration)
	{
		DTXInspectorContent* recordingConfiguration = [DTXInspectorContent new];
		recordingConfiguration.title = NSLocalizedString(@"Recording Configuration", @"");
		
		content = [NSMutableArray new];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Performance", @"") description:__DTXStringFromBoolean(configuration.recordPerformance)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Sampling Interval", @"") description:[NSFormatter.dtx_durationFormatter stringFromTimeInterval:configuration.samplingInterval]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Thread Information", @"") description:__DTXStringFromBoolean(configuration.recordThreadInformation)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Collect Stack Traces", @"") description:__DTXStringFromBoolean(configuration.collectStackTraces)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Symbolicate Stack Traces", @"") description:__DTXStringFromBoolean(configuration.symbolicateStackTraces)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Collect Open File Names", @"") description:__DTXStringFromBoolean(configuration.collectOpenFileNames)]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Network", @"") description:__DTXStringFromBoolean(configuration.recordNetwork)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Localhost", @"") description:__DTXStringFromBoolean(configuration.recordLocalhostNetwork)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Disable Network Cache", @"") description:__DTXStringFromBoolean(configuration.disableNetworkCache)]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Events", @"") description:__DTXStringFromBoolean(configuration.recordEvents)]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Ignored Event Categories", @"") description:[configuration.ignoredEventCategories.allObjects componentsJoinedByString:@", "]]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Activity", @"") description:__DTXStringFromBoolean(configuration.recordActivity)]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Log Output", @"") description:__DTXStringFromBoolean(configuration.recordLogOutput)]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
		if(recording.hasReactNative)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Profile React Native", @"") description:__DTXStringFromBoolean(configuration.profileReactNative)]];
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Bridge Data", @"") description:__DTXStringFromBoolean(configuration.recordReactNativeBridgeData)]];
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Timers as Activity", @"") description:__DTXStringFromBoolean(configuration.recordReactNativeTimersAsActivity)]];
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Record Internal React Native Activity", @"") description:__DTXStringFromBoolean(configuration.recordInternalReactNativeActivity)]];
		}
		
//		[content addObject:[DTXInspectorContentRow contentRowWithNewLine]];
		
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
	[NSUserDefaults.standardUserDefaults setInteger:0 forKey:DTXInspectorTabKey];
	
	_recordingDescriptionDataSource.managedTableView = nil;
	_sampleDescriptionDataSource.managedTableView = _recordingInfoTableView;
	_nothingLabel.hidden = _sampleDescriptionDataSource != nil;
	_recordingInfoTableView.hidden = _sampleDescriptionDataSource == nil;
}

- (void)selectProfilingInfo
{
	_tabSwitcher.selectedSegment = 1;
	[NSUserDefaults.standardUserDefaults setInteger:1 forKey:DTXInspectorTabKey];
	
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
	if(menuItem.action == @selector(copy:) || menuItem.action == @selector(copyFromContext:))
	{
		return [_inspectorDataProvider canCopyInView:(id)self.view.window.firstResponder];
	}
	
	if(menuItem.action == @selector(saveAsFromContext:))
	{
		return _inspectorDataProvider.canSaveAs;
	}
	
	return [super validateMenuItem:menuItem];
}

- (void)copy:(id)sender
{
	[_inspectorDataProvider copyInView:(id)self.view.window.firstResponder sender:sender];
}

- (IBAction)copyFromContext:(id)sender
{
	[_inspectorDataProvider copyInView:sender sender:sender];
}

- (IBAction)saveAsFromContext:(id)sender
{
	[_inspectorDataProvider saveAs:sender inWindow:self.view.window];
}

- (BOOL)expandPreview
{
	__block BOOL didExpand = NO;
	
	[_sampleDescriptionDataSource.contentArray enumerateObjectsUsingBlock:^(DTXInspectorContent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:DTXFileInspectorContent.class])
		{
			DTXFileInspectorContent* fileContent = (id)obj;
			didExpand = [fileContent expandPreview];
			
			*stop = NO;
		}
	}];
	
	return didExpand;
}

@end
