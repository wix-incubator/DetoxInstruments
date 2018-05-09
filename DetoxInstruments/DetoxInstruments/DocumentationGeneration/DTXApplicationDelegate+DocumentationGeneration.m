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

@implementation DTXApplicationDelegate (DocumentationGeneration)

+ (void)load
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSMenu* helpMenu = NSApp.mainMenu.itemArray.lastObject.submenu;
		
		[helpMenu addItem:[NSMenuItem separatorItem]];
		[helpMenu addItemWithTitle:@"Generate Documentation Screenshots" action:@selector(_generateDocScreenshots:) keyEquivalent:@""];
		
		__classToNameMapping = @{
								 NSStringFromClass(DTXCPUUsagePlotController.class): @{@"name": @"CPUUsage", @"inspectorSample": @166},
								 NSStringFromClass(DTXDiskReadWritesPlotController.class): @{@"name": @"DiskActivity", @"displaySample": @199},
								 NSStringFromClass(DTXFPSPlotController.class): @{@"name": @"FPS"},
								 NSStringFromClass(DTXMemoryUsagePlotController.class): @{@"name": @"MemoryUsage", @"displaySample": @175},
								 NSStringFromClass(DTXCompactNetworkRequestsPlotController.class): @{@"name": @"NetworkActivity", @"displaySample": @175, @"scrollPercentage": @0.8},
								 };
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
	
	[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/example.dtxprof"] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		
		DTXInstrumentsWindowController* windowController = document.windowControllers.firstObject;
		
		[windowController _drainLayout];
		
		[windowController _setWindowSizeToScreenPercentage:CGPointMake(0.7, 0.9)];
		
		[__classToNameMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			[self _createInstrumentScreenshotForPlotControllerClass:NSClassFromString(key) windowController:windowController];
		}];
		
		
		[windowController _drainLayout];
		[windowController close];
		[windowController _drainLayout];
		
		exit(0);
	}];
}

- (void)_createInstrumentScreenshotForPlotControllerClass:(Class)cls windowController:(DTXInstrumentsWindowController*)windowController
{
	NSDictionary* info = __classToNameMapping[NSStringFromClass(cls)];
	NSString* name = info[@"name"];
	NSInteger displaySample = [info[@"displaySample"] ?: @22 integerValue];
	NSInteger inspectorSample = [info[@"inspectorSample"] ?: @22 integerValue];
	CGFloat scrollPercentage = [info[@"scrollPercentage"] ?: @0.5 doubleValue];
	
	[windowController _deselectAllPlotControllers];
	[windowController _selectSampleAtIndex:displaySample forPlotControllerClass:cls];
	
	NSBitmapImageRep* rep = (NSBitmapImageRep*)[windowController _snapshotForPlotControllerOfClass:cls].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@.png", name]].path atomically:YES];
	
	[windowController _selectPlotControllerOfClass:cls];
	
	[windowController _deselectAnyDetail];
	[windowController _setBottomSplitAtPercentage:0.35];
	[windowController _scrollBottomPaneToPercentage:scrollPercentage];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane.png", name]].path atomically:YES];
	
	[windowController _selectSampleAtIndex:inspectorSample forPlotControllerClass:cls];
	[windowController _setBottomSplitAtPercentage:0.6];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForInspectorPane].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_InspectorPane.png", name]].path atomically:YES];
}


@end

#endif
