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
#import "DTXProfilingTargetManagementWindowController+DocumentationGeneration.h"
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
//		NSMenu* helpMenu = NSApp.mainMenu.itemArray.lastObject.submenu;
		NSMenu* debugMenu = [[NSMenu alloc] initWithTitle:@"Debug"];
		
		NSMenuItem* item = [NSMenuItem new];
		item.title = @"Generate Documentation Screenshots";
		item.action = @selector(_generateDocScreenshots:);
		
		[debugMenu addItem:item];
		
		NSMenuItem* debugMenuItem = [NSMenuItem new];
		debugMenuItem.submenu = debugMenu;
		
		[NSApp.mainMenu addItem:debugMenuItem];
		
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
	__block NSScreen* retinaScreen = nil;
	
	[NSScreen.screens enumerateObjectsUsingBlock:^(NSScreen * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.backingScaleFactor >= 2)
		{
			*stop = YES;
			retinaScreen = obj;
		}
	}];
	
	if(retinaScreen == nil)
	{
		NSBeep();
		
		NSAlert *errorAlert = [[NSAlert alloc] init];
		errorAlert.alertStyle = NSAlertStyleCritical;
		errorAlert.messageText = @"No retina screen found";
		errorAlert.informativeText = @"Screenshots must be generated on a retina screen.";
		[errorAlert runModal];
		
		return;
	}
	
	[NSApp.orderedDocuments enumerateObjectsUsingBlock:^(NSDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj close];
	}];
	
	NSDocument* newDocument = [NSDocumentController.sharedDocumentController openUntitledDocumentAndDisplay:YES error:NULL];
	DTXInstrumentsWindowController* windowController = newDocument.windowControllers.firstObject;
	
	[windowController.window constrainFrameRect:windowController.window.frame toScreen:retinaScreen];
	[windowController.window makeKeyAndOrderFront:nil];
	[windowController _setWindowSize:NSMakeSize(1344, 945)];
	[windowController _setBottomSplitAtPercentage:0.53];
	[windowController _drainLayout];
	
	NSBitmapImageRep* rep = (NSBitmapImageRep*)[windowController _snapshotForTargetSelection].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Discovered.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Integration_Discovered.png"].path atomically:YES];
	
	DTXProfilingTargetManagementWindowController* managementWindowController = [windowController _openManagementWindowController];
	
	[managementWindowController _drainLayout];
	
	[managementWindowController _activateControllerAtIndex:0];
	[managementWindowController _expandFolders];
	[managementWindowController _drainLayout];
	rep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_ContainerFiles.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:1];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* manageRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[manageRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_Pasteboard.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:2];
	[managementWindowController _expandDefaults];
	[managementWindowController _drainLayout];
	[managementWindowController _selectSomethingInDefaults];
	[managementWindowController _drainLayout];
	rep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_UserDefaults.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:3];
	[managementWindowController _expandCookies];
	[managementWindowController _drainLayout];
	[managementWindowController _selectDateInCookies];
	[managementWindowController _drainLayout];
	[managementWindowController _drainLayout];
	[managementWindowController _drainLayout];
	rep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_Cookies.png"].path atomically:YES];
	
	[managementWindowController.window close];
	
	[managementWindowController _drainLayout];
	[windowController _drainLayout];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForRecordingSettings].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"ProfilingOptions_ProfilingOptions.png"].path atomically:YES];
	
	[newDocument close];
	
	[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/example.dtxprof"] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		
		DTXInstrumentsWindowController* windowController = document.windowControllers.firstObject;
		[document setValue:@"Example App" forKeyPath:@"recording.appName"];
		[windowController _setRecordingButtonsVisible:NO];
		[windowController.window setFrame:[windowController.window constrainFrameRect:windowController.window.frame toScreen:retinaScreen] display:YES];
		[windowController.window makeKeyAndOrderFront:nil];
		[windowController _setWindowSize:NSMakeSize(1344, 945)];
		[windowController _setBottomSplitAtPercentage:0.53];
		[windowController _removeDetailVerticalScroller];
		[windowController _drainLayout];
		
		[windowController _selectSampleAtIndex:__defaultSample.integerValue forPlotControllerClass:DTXCPUUsagePlotController.class];
		
		[windowController _drainLayout];
		
		NSBitmapImageRep* repIntro = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
		[[repIntro representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Document.png"].path atomically:YES];
		
		repIntro = (NSBitmapImageRep*)[self _introImageWithRecordingWindowRep:repIntro managementWindowRep:manageRep].representations.firstObject;
		[[repIntro representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Intro.png"].path atomically:YES];
		
		[windowController _setWindowSize:NSMakeSize(1176, 945)];
		[windowController _setRecordingButtonsVisible:YES];
		[windowController _drainLayout];
		
		repIntro = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;

		NSBitmapImageRep* rep = (NSBitmapImageRep*)[self _exampleImageWithExistingRep:repIntro].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_Example.png"].path atomically:YES];

		repIntro = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;

		rep = (NSBitmapImageRep*)[self _toolbarImageWithExistingRep:repIntro].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_Toolbar.png"].path atomically:YES];

		[windowController _setRecordingButtonsVisible:NO];
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

- (NSImage*)_exampleImageWithExistingRep:(NSBitmapImageRep*)rep
{
	const CGFloat exampleImageWidthPadding = 440;
	const CGFloat exampleImageHeightPadding = 120;
	const CGFloat exampleFontSize = 80;
	const CGFloat toolbarTitleXOffset = 1160;
	const CGFloat lineLength = 172;
	
	NSMutableParagraphStyle* pStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
	pStyle.alignment = NSTextAlignmentCenter;
	
	NSImage* exampleImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width + exampleImageWidthPadding * 2, rep.size.height + exampleImageHeightPadding)];
	[exampleImage lockFocus];
	
	[rep drawAtPoint:NSMakePoint(exampleImage.size.width / 2 - rep.size.width / 2, exampleImage.size.height / 2 - rep.size.height / 2 - exampleImageHeightPadding)];
	
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:@"Toolbar" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:exampleFontSize weight:(NSFontWeightRegular + NSFontWeightThin) / 2.2], NSParagraphStyleAttributeName: pStyle}];
	[attr drawAtPoint:NSMakePoint(toolbarTitleXOffset, exampleImage.size.height - 44 - attr.size.height)];
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	
	path.lineWidth = 6;
	
	[path moveToPoint:NSMakePoint(toolbarTitleXOffset + attr.size.width / 2, exampleImage.size.height - 44 - attr.size.height - 10)];
	[path lineToPoint:NSMakePoint(toolbarTitleXOffset + attr.size.width / 2, exampleImage.size.height - 44 - attr.size.height - 10 - lineLength)];
	
	const CGFloat timelineTitleYOffset = exampleImage.size.height - 700;
	
	attr = [[NSAttributedString alloc] initWithString:@"Timeline" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:exampleFontSize weight:(NSFontWeightRegular + NSFontWeightThin) / 2.2], NSParagraphStyleAttributeName: pStyle}];
	[attr drawInRect:(NSRect){570 - lineLength - 20 - attr.size.width, timelineTitleYOffset - attr.size.height / 2 + 20, attr.size}];
	
	[path moveToPoint:NSMakePoint(570, timelineTitleYOffset)];
	[path lineToPoint:NSMakePoint(570 - lineLength, timelineTitleYOffset)];
	
	const CGFloat detailTitleYOffset = exampleImage.size.height - 1600;
	
	attr = [[NSAttributedString alloc] initWithString:@"Detail\nPane" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:exampleFontSize weight:(NSFontWeightRegular + NSFontWeightThin) / 2.2], NSParagraphStyleAttributeName: pStyle}];
	[attr drawInRect:(NSRect){570 - lineLength - 20 - attr.size.width, detailTitleYOffset - attr.size.height / 2 + 20, attr.size}];
	
	[path moveToPoint:NSMakePoint(570, detailTitleYOffset)];
	[path lineToPoint:NSMakePoint(570 - lineLength, detailTitleYOffset)];
	
	const CGFloat inspectorTitleYOffset = exampleImage.size.height - 1890;
	
	attr = [[NSAttributedString alloc] initWithString:@"Inspector\nPane" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:exampleFontSize weight:(NSFontWeightRegular + NSFontWeightThin) / 2.2], NSParagraphStyleAttributeName: pStyle}];
	[attr drawInRect:(NSRect){exampleImage.size.width - 572 + lineLength + 20, inspectorTitleYOffset - attr.size.height / 2 + 20, attr.size}];
	
	[path moveToPoint:NSMakePoint(exampleImage.size.width - 572, inspectorTitleYOffset)];
	[path lineToPoint:NSMakePoint(exampleImage.size.width - 572 + lineLength, inspectorTitleYOffset)];
	
	[path stroke];
	
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, exampleImage.size}];
	[exampleImage unlockFocus];
	[exampleImage removeRepresentation:exampleImage.representations.firstObject];
	[exampleImage addRepresentation:rep];
	
	return exampleImage;
}

- (NSImage*)_toolbarImageWithExistingRep:(NSBitmapImageRep*)rep
{
	NSImage* toolbarImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width, 174)];
	[toolbarImage lockFocus];
	
	[rep drawAtPoint:NSMakePoint(0, toolbarImage.size.height - rep.size.height)];
	
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, toolbarImage.size}];
	[toolbarImage unlockFocus];
	[toolbarImage removeRepresentation:toolbarImage.representations.firstObject];
	[toolbarImage addRepresentation:rep];
	
	return toolbarImage;
}

- (NSImage*)_introImageWithRecordingWindowRep:(NSBitmapImageRep*)recWinRep managementWindowRep:(NSBitmapImageRep*)manageRep
{
	NSImage* introImage = [[NSImage alloc] initWithSize:NSMakeSize(recWinRep.size.width + manageRep.size.width / 4, recWinRep.size.height + manageRep.size.height / 5)];
	[introImage lockFocus];
	
	[recWinRep drawAtPoint:NSMakePoint(0, introImage.size.height - recWinRep.size.height)];
	[manageRep drawInRect:(NSRect){NSMakePoint(introImage.size.width - manageRep.size.width, 0), manageRep.size} fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	recWinRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, introImage.size}];
	[introImage unlockFocus];
	[introImage removeRepresentation:introImage.representations.firstObject];
	[introImage addRepresentation:recWinRep];
	
	return introImage;
}

@end

#endif
