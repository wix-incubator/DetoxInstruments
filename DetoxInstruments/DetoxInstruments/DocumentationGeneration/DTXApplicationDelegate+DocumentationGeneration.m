//
//  DTXApplicationDelegate+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/8/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifdef DEBUG

#import "DTXApplicationDelegate+DocumentationGeneration.h"
#import "DTXInstrumentsWindowController+DocumentationGeneration.h"
#import "NSWindow+Snapshotting.h"

#import "DTXAxisHeaderPlotController.h"
#import "DTXCPUUsagePlotController.h"
#import "DTXThreadCPUUsagePlotController.h"
#import "DTXMemoryUsagePlotController.h"
#import "DTXFPSPlotController.h"
#import "DTXDiskReadWritesPlotController.h"
#import "DTXCompactNetworkRequestsPlotController.h"
#import "DTXRNCPUUsagePlotController.h"
#import "DTXRNBridgeCountersPlotController.h"
#import "DTXRNBridgeDataTransferPlotController.h"

#import "DTXManagedPlotControllerGroup.h"

static NSDictionary<NSString*, NSDictionary<NSString*, id>*>* __classToNameMapping;
static NSNumber* __defaultSample;
static const CGFloat __inspectorPaneOverviewImagePadding = 35;

@implementation DTXApplicationDelegate (DocumentationGeneration)

+ (void)load
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSMenu* helpMenu = NSApp.mainMenu.itemArray.lastObject.submenu;
		
		[helpMenu addItem:[NSMenuItem separatorItem]];
		[helpMenu addItemWithTitle:@"Generate Documentation Screenshots" action:@selector(_generateDocScreenshots:) keyEquivalent:@""];
		
		__classToNameMapping = @{
								 NSStringFromClass(DTXCPUUsagePlotController.class): @{@"name": @"CPUUsage", @"inspectorSample": @166, @"includeInRecordingDocumentInspectorPane": @0},
								 NSStringFromClass(DTXDiskReadWritesPlotController.class): @{@"name": @"DiskActivity", @"displaySample": @199},
								 NSStringFromClass(DTXFPSPlotController.class): @{@"name": @"FPS"},
								 NSStringFromClass(DTXMemoryUsagePlotController.class): @{@"name": @"MemoryUsage", @"displaySample": @175},
								 NSStringFromClass(DTXCompactNetworkRequestsPlotController.class): @{@"name": @"NetworkActivity", @"displaySample": @175, @"scrollPercentage": @0.8, @"includeInRecordingDocumentInspectorPane": @1},
								 @"NULL":@{@"includeInRecordingDocumentInspectorPane": @2},
								 };
		
		__defaultSample = @22;
	});
}

- (NSURL*)_resourcesURL
{
	return [[[NSURL URLWithString:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Resources/"] URLByStandardizingPath];
}

- (IBAction)_generateDocScreenshots:(id)sender
{
	[NSApp.orderedDocuments enumerateObjectsUsingBlock:^(NSDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj close];
	}];
	
	NSDocument* newDocument = [NSDocumentController.sharedDocumentController openUntitledDocumentAndDisplay:YES error:NULL];
	DTXInstrumentsWindowController* windowController = newDocument.windowControllers.firstObject;
	
	[windowController _setWindowSizeToScreenPercentage:CGPointMake(0.8, 0.9)];
	[windowController _drainLayout];
	
	NSBitmapImageRep* rep = (NSBitmapImageRep*)[windowController _snapshotForTargetSelection].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Discovered.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Integration_Discovered.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForRecordingSettings].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"ProfilingOptions_ProfilingOptions.png"].path atomically:YES];
	
	[newDocument close];
	
	[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/example.dtxprof"] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		
		DTXInstrumentsWindowController* windowController = document.windowControllers.firstObject;
		
		[windowController _setWindowSizeToScreenPercentage:CGPointMake(0.8, 0.9)];
		
		[windowController _drainLayout];
		
		[windowController _selectSampleAtIndex:__defaultSample.integerValue forPlotControllerClass:DTXCPUUsagePlotController.class];
		
		[windowController _drainLayout];
		
		NSBitmapImageRep* rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Intro.png"].path atomically:YES];
		
		[windowController _setWindowSizeToScreenPercentage:CGPointMake(0.7, 0.9)];
		[windowController _drainLayout];
		
		NSImage* inspectorPaneOverviewImage = [[NSImage alloc] initWithSize:NSMakeSize(320 * 3 + __inspectorPaneOverviewImagePadding * 6, 511)];
		
		[__classToNameMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			[self _createInstrumentScreenshotForPlotControllerClass:NSClassFromString(key) windowController:windowController inspectorPaneOverviewImage:inspectorPaneOverviewImage];
		}];
		
		[inspectorPaneOverviewImage lockFocus];
		rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, inspectorPaneOverviewImage.size}];
		[inspectorPaneOverviewImage unlockFocus];
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_InspectorPane.png"].path atomically:YES];
		
		[windowController _deselectAnyPlotControllers];
		[windowController _selectSampleAtIndex:175 forPlotControllerClass:DTXMemoryUsagePlotController.class];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForTimeline].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_TimelinePane.png"].path atomically:YES];
		
		[windowController _selectPlotControllerOfClass:DTXCompactNetworkRequestsPlotController.class];
		[windowController _deselectAnyDetail];
		[windowController _setBottomSplitAtPercentage:0.6];
		[windowController _scrollBottomPaneToPercentage:0.8];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_DetailPane.png"].path atomically:YES];
		
		[windowController _drainLayout];
		[document close];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[NSUserDefaults.standardUserDefaults synchronize];
			exit(0);
		});
	}];
}

- (void)_createInstrumentScreenshotForPlotControllerClass:(Class)cls windowController:(DTXInstrumentsWindowController*)windowController inspectorPaneOverviewImage:(NSImage*)inspectorPaneOverviewImage;
{
	NSDictionary* info = __classToNameMapping[NSStringFromClass(cls) ?: @"NULL"];
	NSBitmapImageRep* rep;
	if(cls != nil)
	{
		NSString* name = info[@"name"];
		NSInteger displaySample = [info[@"displaySample"] ?: __defaultSample integerValue];
		NSInteger inspectorSample = [info[@"inspectorSample"] ?: __defaultSample integerValue];
		CGFloat scrollPercentage = [info[@"scrollPercentage"] ?: @0.5 doubleValue];
		
		[windowController _deselectAnyPlotControllers];
		[windowController _selectSampleAtIndex:displaySample forPlotControllerClass:cls];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForPlotControllerOfClass:cls].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@.png", name]].path atomically:YES];
		
		[windowController _selectPlotControllerOfClass:cls];
		
		[windowController _deselectAnyDetail];
		[windowController _setBottomSplitAtPercentage:0.35];
		[windowController _scrollBottomPaneToPercentage:scrollPercentage];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane.png", name]].path atomically:YES];
		
		[windowController _selectSampleAtIndex:inspectorSample forPlotControllerClass:cls];
		[windowController _setBottomSplitAtPercentage:0.6];
		[windowController _selectExtendedDetailInspector];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForInspectorPane].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_InspectorPane.png", name]].path atomically:YES];
	}
	else
	{
		[windowController _selectProfilingInfoInspector];
		[windowController _setBottomSplitAtPercentage:0.6];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForInspectorPane].representations.firstObject;
	}
	
	NSNumber* idx = info[@"includeInRecordingDocumentInspectorPane"];
	if(idx)
	{
		[inspectorPaneOverviewImage lockFocus];
		
		[rep drawAtPoint:NSMakePoint(__inspectorPaneOverviewImagePadding + idx.unsignedIntegerValue * ((__inspectorPaneOverviewImagePadding * 2) + rep.size.width), 0)];
		
		[inspectorPaneOverviewImage unlockFocus];
	}
}


@end

#endif
