//
//  DTXApplicationDelegate+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/8/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#if DEBUG

#import "DTXApplicationDelegate+DocumentationGeneration.h"
#import "DTXWindowController+DocumentationGeneration.h"
#import "CCNPreferencesWindowController+DocumentationGeneration.h"
#import "DTXProfilingTargetManagementWindowController+DocumentationGeneration.h"
#import "DTXInstrumentsPreferencesWindowController+DocumentationGeneration.h"
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
#import "DTXEventsPlotController.h"
#import "DTXActivityPlotController.h"
#import "DTXRNAsyncStoragePlotController.h"
#import "NSAppearance+UIAdditions.h"

#import "DTXManagedPlotControllerGroup.h"
#import "NSView+UIAdditions.h"
#import "DTXDebugMenuGenerator.h"
#import "NSImage+UIAdditions.h"

#import "DTXRequestDocument.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@import ObjectiveC;

@interface NSNetServiceBrowser (DTXDebug) @end
@implementation NSNetServiceBrowser (DTXDebug)

- (void)__dtx_searchForServicesOfType:(NSString *)type inDomain:(NSString *)domainString
{
}

+ (void)__dtx_applyDebugIgnore
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getInstanceMethod(self, @selector(searchForServicesOfType:inDomain:));
		Method m2 = class_getInstanceMethod(self, @selector(__dtx_searchForServicesOfType:inDomain:));
		
		method_exchangeImplementations(m1, m2);
	});
}

@end

static NSBitmapImageRep* __DTXCroppedRep(NSBitmapImageRep* rep, NSEdgeInsets insets)
{
	NSImage* rvImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width - insets.left - insets.right, rep.size.height - insets.bottom - insets.top)];
	[rvImage lockFocus];
	[rep drawInRect:(NSRect){0, 0, rvImage.size} fromRect:NSMakeRect(insets.left, insets.bottom, rvImage.size.width, rvImage.size.height) operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, rvImage.size}];
	[rvImage unlockFocus];
	
	return rep;
}

static NSBitmapImageRep* __DTXThemeBackgroundRep(NSBitmapImageRep* rep)
{
	NSImage* rvImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width, rep.size.height)];
	[rvImage lockFocus];
	[(NSApp.effectiveAppearance.isDarkAppearance ? [NSColor colorWithRed:33.0/255.0 green:33.0/255.0 blue:34.0/255.0 alpha:1.0] : NSColor.whiteColor) setFill];
	NSRect rect = (NSRect){0, 0, rvImage.size};
	NSRectFill(rect);
	[rep drawInRect:rect fromRect:rect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:rect];
	[rvImage unlockFocus];
	
	return rep;
}

static NSDictionary<NSString*, NSDictionary<NSString*, id>*>* __classToNameMapping;
static NSDictionary<NSString*, NSDictionary<NSString*, id>*>* __classToNameRNMapping;
static NSDictionary<NSNumber*, NSNumber*>* __appleAccentColorMapping;
static NSDictionary<NSNumber*, NSString*>* __appleHighlightColorMapping;
static NSNumber* __defaultSample;
static NSNumber* __defaultSampleRN;
static const CGFloat __inspectorPaneOverviewImagePadding = 35;
static const CGFloat __inspectorPercentage = 0.85;
static const CGFloat __inspectorLowkeyPercentage = 0.45;

@implementation DTXApplicationDelegate (DocumentationGeneration)

+ (void)_addColorsToMenuItem:(NSMenuItem*)menuItem
{
	NSMenu* colors = [NSMenu new];
	menuItem.submenu = colors;
	
	NSArray* colorNames = @[@"Blue", @"Purple", @"Pink", @"Red", @"Orange", @"Yellow", @"Green", @"Graphite"];
	NSArray* colorTints = @[[NSColor systemBlueColor],
							[NSColor systemPurpleColor],
							[NSColor systemPinkColor],
							[NSColor systemRedColor],
							[NSColor systemOrangeColor],
							[NSColor systemYellowColor],
							[NSColor systemGreenColor],
							[NSColor systemGrayColor]
							];
	[colorNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMenuItem* colorItem = [NSMenuItem new];
		colorItem.title = obj;
		colorItem.tag = idx;
		colorItem.image = [[NSImage imageNamed:@"color_indicator"] imageTintedWithColor:colorTints[idx]];
		colorItem.action = @selector(_generateDocScreenshots:);
		[colors addItem:colorItem];
	}];
}

+ (void)load
{
	[NSUserDefaults.standardUserDefaults removeObjectForKey:@"AppleAccentColor"];
	[NSUserDefaults.standardUserDefaults removeObjectForKey:@"AppleHighlightColor"];
	[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DetoxInstrumentsDocGeneration"];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//		NSMenu* helpMenu = NSApp.mainMenu.itemArray.lastObject.submenu;
		NSMenu* debugMenu = [[NSMenu alloc] initWithTitle:@"Debug"];
		
		NSMenuItem* item = [NSMenuItem new];
		item.title = @"Generate Screenshots";
		item.enabled = NO;
		[debugMenu addItem:item];
		
		NSMenuItem* darkAppearance = [NSMenuItem new];
		darkAppearance.title = @"Dark Appearance";
		darkAppearance.tag = 1;
		[self _addColorsToMenuItem:darkAppearance];
		[debugMenu addItem:darkAppearance];
		
		NSMenuItem* lightAppearance = [NSMenuItem new];
		lightAppearance.title = @"Light Appearance";
		lightAppearance.tag = 0;
		[self _addColorsToMenuItem:lightAppearance];
		[debugMenu addItem:lightAppearance];
		
		[debugMenu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem* ignoreVersion = [NSMenuItem new];
		ignoreVersion.title = @"Ignore Incompatible Profiler Versions";
		[ignoreVersion bind:NSValueBinding toObject:NSUserDefaults.standardUserDefaults withKeyPath:@"DTXDebugIgnoreIncompatibleProfilers" options:nil];
		[debugMenu addItem:ignoreVersion];
		
		NSMenuItem* debugMenuItem = [NSMenuItem new];
		debugMenuItem.submenu = debugMenu;
		
		[NSApp.mainMenu addItem:debugMenuItem];
		
		__classToNameMapping = @{
								 NSStringFromClass(DTXCPUUsagePlotController.class): @{@"name": @"CPUUsage", @"inspectorSample": @166, @"includeInRecordingDocumentInspectorPane": @0},
								 NSStringFromClass(DTXDiskReadWritesPlotController.class): @{@"name": @"DiskActivity", @"displaySample": @218, @"lowkeyInspector": @YES},
								 NSStringFromClass(DTXFPSPlotController.class): @{@"name": @"FPS", @"displaySample": @62, @"lowkeyInspector": @YES},
								 NSStringFromClass(DTXMemoryUsagePlotController.class): @{@"name": @"MemoryUsage", @"displaySample": @113, @"lowkeyInspector": @YES},
								 NSStringFromClass(DTXCompactNetworkRequestsPlotController.class): @{@"name": @"NetworkActivity", @"inspectorSample": @111, @"displaySample": @359, @"scrollPercentage": @0.8, @"includeInRecordingDocumentInspectorPane": @1}, @"NULL":@{@"includeInRecordingDocumentInspectorPane": @2},
								 NSStringFromClass(DTXEventsPlotController.class): @{@"name": @"Events", @"displaySample": @3, @"outlineBreadcrumbs": @[@1, @0, @3], @"lowkeyInspector": @YES}, @"NULL":@{@"includeInRecordingDocumentInspectorPane": @2},
								 NSStringFromClass(DTXActivityPlotController.class): @{@"name": @"Activity", @"displaySample": NSNull.null, @"outlineBreadcrumbs": @[@2, @0], @"lowkeyInspector": @YES}, @"NULL":@{@"includeInRecordingDocumentInspectorPane": @2, @"zoom": @4},
								 };
		
		__classToNameRNMapping = @{
								   NSStringFromClass(DTXRNCPUUsagePlotController.class): @{@"name": @"RNJSThread", @"lowkeyInspector": @YES},
								   NSStringFromClass(DTXRNBridgeCountersPlotController.class): @{@"name": @"RNBridgeCounters", @"lowkeyInspector": @YES},
								   NSStringFromClass(DTXRNBridgeDataTransferPlotController.class): @{@"name": @"RNBridgeData", @"lowkeyInspector": @YES},
								   NSStringFromClass(DTXRNAsyncStoragePlotController.class): @{@"name": @"RNAsyncStorage", @"lowkeyInspector": @YES},
								   };
		
		__defaultSample = @22;
		__defaultSampleRN = @22;
		
		__appleAccentColorMapping = @{
									  @0: @100,
									  @1: @5,
									  @2: @6,
									  @3: @0,
									  @4: @1,
									  @5: @2,
									  @6: @3,
									  @7: @-1
									  };
		
		__appleHighlightColorMapping = @{
										 @0: @"",
										 @1: @"0.968627 0.831373 1.000000 Purple",
										 @2: @"1.000000 0.749020 0.823529 Pink",
										 @3: @"1.000000 0.733333 0.721569 Red",
										 @4: @"1.000000 0.874510 0.701961 Orange",
										 @5: @"1.000000 0.937255 0.690196 Yellow",
										 @6: @"0.752941 0.964706 0.678431 Green",
										 @7: @"0.847059 0.847059 0.862745 Graphite"
										 };
	});
}

- (NSURL*)_resourcesURL
{
	return [[[NSURL URLWithString:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Resources/"] URLByStandardizingPath];
}

- (IBAction)_generateDocScreenshots:(NSMenuItem*)sender
{
	[NSApp.orderedDocuments enumerateObjectsUsingBlock:^(NSDocument * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj close];
	}];
	
	//performSelector: API must be used here for some reason. dispatch_after does not work.
	[self performSelector:@selector(__generateMiddleman:) withObject:sender afterDelay:1.0];
}

- (void)__generateMiddleman:(NSMenuItem*)sender
{
	[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DetoxInstrumentsDocGeneration"];
	
	NSUInteger menuAppearance = sender.parentItem.tag;
	NSUInteger menuAccent = sender.tag;

	NSAppearance.currentAppearance = NSApp.appearance = [NSAppearance appearanceNamed: menuAppearance == 0 ? NSAppearanceNameAqua : NSAppearanceNameDarkAqua];
	[NSUserDefaults.standardUserDefaults setObject:__appleAccentColorMapping[@(menuAccent)] forKey:@"AppleAccentColor"];
	[NSUserDefaults.standardUserDefaults setObject:__appleHighlightColorMapping[@(menuAccent)] forKey:@"AppleHighlightColor"];
	[NSNotificationCenter.defaultCenter postNotificationName:@"kCUINotificationAquaColorVariantChanged" object:nil];
	
	[self __generate];
}

- (void)__generate
{
	[NSNetServiceBrowser __dtx_applyDebugIgnore];
	
	NSBitmapImageRep* rep;
	
	NSSize buttonImageExportSize = NSMakeSize(8, 8);
	
	NSImage* img = [[NSImage imageNamed:@"stopRecording"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_Stop.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"flag"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_Flag.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"NowTemplate"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_Follow.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"NSActionTemplate"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_Manage.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"NSActionTemplate"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_TimelineOptions.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"NSPrivateChaptersTemplate"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_Customize.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"Bottom"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_DetailsPane.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"Right"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_InspectorPane.png"].path atomically:YES];
	
	img = [[NSImage imageNamed:@"expand_preview"] imageTintedWithColor:NSColor.blackColor];
	img.size = buttonImageExportSize;
	[img lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, img.size}];
	[img unlockFocus];
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Button_ExpandPreview.png"].path atomically:YES];
	
	NSDocument* newDocument = [NSDocumentController.sharedDocumentController openUntitledDocumentAndDisplay:YES error:NULL];
	DTXWindowController* windowController = newDocument.windowControllers.firstObject;
	
	[windowController.window makeKeyAndOrderFront:nil];
	[windowController _setWindowSize:NSMakeSize(1344, 945)];
	[windowController _setBottomSplitAtPercentage:0.53];
	[windowController _drainLayout];
	
	[self _createConsoleMenuScreenshotWithWindowController:windowController];
	[self _createBridgeDataMenuScreenshotWithWindowController:windowController];
	[self _createAsyncStorageMenuScreenshotWithWindowController:windowController];
	[self _createEventsDetailMenuScreenshotWithWindowController:windowController];
	[self _createAppLaunchProfileMenuScreenshotWithWindowController:windowController];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForTargetSelection].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Discovered.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Integration_Discovered.png"].path atomically:YES];
	
	DTXProfilingTargetManagementWindowController* managementWindowController = [windowController _openManagementWindowController];
	
	[managementWindowController _drainLayout];
	
	[managementWindowController _activateControllerAtIndex:0];
	[managementWindowController _expandFolders];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* containerRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[containerRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_ContainerFiles.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:1];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* pasteboardRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[pasteboardRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_Pasteboard.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:2];
	[managementWindowController _expandDefaults];
	[managementWindowController _drainLayout];
	[managementWindowController _selectSomethingInDefaults];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* defaultsRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[defaultsRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_UserDefaults.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:4];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* asyncStorageRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[asyncStorageRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_AsyncStorage.png"].path atomically:YES];
	
	[managementWindowController _activateControllerAtIndex:3];
	[managementWindowController _expandCookies];
	[managementWindowController _drainLayout];
	[managementWindowController _selectDateInCookies];
	[managementWindowController _drainLayout];
	[managementWindowController _drainLayout];
	[managementWindowController _drainLayout];
	NSBitmapImageRep* cookiesRep = (NSBitmapImageRep*)[managementWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[cookiesRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_Cookies.png"].path atomically:YES];
	
	[[(NSBitmapImageRep*)[self _combineManagementImages:containerRep :cookiesRep :defaultsRep :pasteboardRep :asyncStorageRep].representations.firstObject representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Management_All.png"].path atomically:YES];
	
	[managementWindowController.window close];
	
	[managementWindowController _drainLayout];
	[windowController _drainLayout];
	
	[windowController _dismissTargetSelection];
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	
	[windowController.window makeKeyWindow];
	
	[newDocument setValue:@"Example App" forKey:@"localRecordingPendingAppName"];
	
	[newDocument setValue:@(DTXRecordingLocalRecordingProfilingStateWaitingForAppLaunch) forKey:@"localRecordingProfilingState"];
	[windowController _drainLayout];
	rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"AppLaunch_Waiting.png"].path atomically:YES];
	
	[newDocument setValue:@(DTXRecordingLocalRecordingProfilingStateWaitingForAppData) forKey:@"localRecordingProfilingState"];
	[windowController _drainLayout];
	rep = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"AppLaunch_Recording.png"].path atomically:YES];
	
	[newDocument close];
	
	NSObject* delegate = NSApp.delegate;
	[delegate performSelector:NSSelectorFromString(@"showPreferencesWindow:") withObject:nil];
	DTXInstrumentsPreferencesWindowController* prefs = [delegate valueForKey:@"_preferencesWindowController"];
	
	rep = (NSBitmapImageRep*)[self _snapshotForGeneralFromPrefs:prefs].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Preferences_General.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[self _snapshotForCLIFromPrefs:prefs].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Preferences_CLI.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[self _snapshotForRecordingSettingsFromPrefs:prefs].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Preferences_Profiling.png"].path atomically:YES];
	
	rep = (NSBitmapImageRep*)[self _snapshotForIgnoredCategoriesFromPrefs:prefs].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Preferences_Profiling_IgnoredEventsCategories.png"].path atomically:YES];
	
	[prefs.window close];
	[prefs _drainLayout];
	
	DTXRequestDocument* requestDocument = [NSDocumentController.sharedDocumentController makeDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/RequestsPlayground.dtxrequest"] ofType:@"com.wix.dtxinst.request" error:NULL];
	[NSDocumentController.sharedDocumentController addDocument:requestDocument];
	[requestDocument makeWindowControllers];
	[requestDocument showWindows];

	DTXRequestsPlaygroundWindowController* requestWindowController = requestDocument.windowControllers.firstObject;
	[(NSTabView*)[requestWindowController.contentViewController valueForKey:@"tabView"] selectTabViewItem:[requestWindowController.contentViewController valueForKey:@"bodyTabViewItem"]];
	
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	
	NSBitmapImageRep* rplaygroundRep = (NSBitmapImageRep*)[requestWindowController.window snapshotForCachingDisplay].representations.firstObject;
	[[rplaygroundRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RequestsPlayground.png"].path atomically:YES];
	[requestWindowController.window close];
	
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	[windowController _drainLayout];
	
	BOOL oldVal = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXPlotSettingsDisplayLabels"];
	[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DTXPlotSettingsDisplayLabels"];
	
	[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/example.dtxrec"] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		
		DTXWindowController* windowController = document.windowControllers.firstObject;
		[[document valueForKeyPath:@"recordings.@firstObject"] setValue:@"Example App" forKeyPath:@"appName"];
		[windowController _setRecordingButtonsVisible:NO];
		[windowController.window makeKeyAndOrderFront:nil];
		[windowController _setWindowSize:NSMakeSize(1344, 945)];
		[windowController _setBottomSplitAtPercentage:0.53];
		[windowController _removeDetailVerticalScroller];
		[windowController _drainLayout];
		[windowController _drainLayout];
		[windowController _drainLayout];
		[windowController _drainLayout];
		
		[windowController _selectSampleAtIndex:__defaultSample.integerValue forPlotControllerClass:DTXCPUUsagePlotController.class];
		
		[windowController _drainLayout];
		
		NSBitmapImageRep* repIntro = (NSBitmapImageRep*)[windowController.window snapshotForCachingDisplay].representations.firstObject;
		[[repIntro representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Document.png"].path atomically:YES];
		
		repIntro = (NSBitmapImageRep*)[self _introImageWithRecordingWindowRep:repIntro managementWindowRep:pasteboardRep requestsPlaygroundRep:rplaygroundRep].representations.firstObject;
		[[repIntro representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Readme_Intro.png"].path atomically:YES];
		
		[windowController _setWindowSize:NSMakeSize(1344, 945)];
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
		
		[windowController _deselectAnyPlotControllers];
		[windowController _selectSampleAtIndex:175 forPlotControllerClass:DTXMemoryUsagePlotController.class];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForTimeline].representations.firstObject;
		[[__DTXThemeBackgroundRep(rep) representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_TimelinePane.png"].path atomically:YES];
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DTXPlotSettingsDisplayLabels"];
		
		NSImage* inspectorPaneOverviewImage = [[NSImage alloc] initWithSize:NSMakeSize(320 * 3 + __inspectorPaneOverviewImagePadding * 6, windowController._plotDetailsSplitViewControllerSize.height * __inspectorPercentage)];
		
		[windowController zoomIn:nil];
		[windowController zoomIn:nil];
		[windowController zoomIn:nil];
		[windowController zoomIn:nil];
		
		[windowController _deselectAnyPlotControllers];
		rep = (NSBitmapImageRep*)[windowController _snapshotForOnlyPlotOfPlotControllerOfClass:DTXCompactNetworkRequestsPlotController.class].representations.firstObject;
		[[__DTXThemeBackgroundRep(__DTXCroppedRep(rep, NSEdgeInsetsMake(0, 0, 3.35 * rep.size.height / 4, 0))) representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_TimelinePane_Labels.png"].path atomically:YES];
		
		[windowController fitAllData:nil];
		
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DTXPlotSettingsDisplayLabels"];
		
		[__classToNameMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			[self _createInstrumentScreenshotForPlotControllerClass:NSClassFromString(key) windowController:windowController inspectorPaneOverviewImage:inspectorPaneOverviewImage mapping:__classToNameMapping];
		}];
		
		[self _createEventsListScreenshotsForWindowController:windowController];
		[self _createActivityListScreenshotsForWindowController:windowController];
		
		[inspectorPaneOverviewImage lockFocus];
		rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, inspectorPaneOverviewImage.size}];
		[inspectorPaneOverviewImage unlockFocus];
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_InspectorPane.png"].path atomically:YES];
		
		[windowController _selectPlotControllerOfClass:DTXCompactNetworkRequestsPlotController.class];
		[windowController _deselectAnyDetail];
		[windowController _setBottomSplitAtPercentage:0.6];
		[windowController _scrollBottomPaneToPercentage:0.8];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_DetailPane.png"].path atomically:YES];
		
		//		NSAppearance.currentAppearance = NSApp.appearance = desiredAppearance;
		
		[windowController _drainLayout];
		[windowController close];
		[document close];
		
		[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:[[NSURL fileURLWithPath:[NSBundle.mainBundle objectForInfoDictionaryKey:@"DTXSourceRoot"]] URLByAppendingPathComponent:@"../Documentation/Example Recording/exampleRN.dtxrec"] display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
			
			DTXWindowController* windowController = document.windowControllers.firstObject;
			
			[[document valueForKeyPath:@"recordings.@firstObject"] setValue:@"Example RN App" forKeyPath:@"appName"];
			[windowController _setRecordingButtonsVisible:NO];
			[windowController.window makeKeyAndOrderFront:nil];
			[windowController _setWindowSize:NSMakeSize(1344, 945)];
			[windowController _setBottomSplitAtPercentage:0.53];
			[windowController _removeDetailVerticalScroller];
			[windowController _drainLayout];
			
			NSBitmapImageRep* rep = (NSBitmapImageRep*)[windowController _snapshotForInstrumentsCustomization].representations.firstObject;
			
			NSImage* customizationPopoverImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width * 3, rep.size.height)];
			[customizationPopoverImage lockFocus];
			
			NSRect centered = (NSRect){93, 20, rep.size};
			[rep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
			
			rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, customizationPopoverImage.size}];
			
			[customizationPopoverImage unlockFocus];
			
			[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_InstrumentCustomization.png"].path atomically:YES];
			
			[windowController _selectSampleAtIndex:__defaultSample.integerValue forPlotControllerClass:DTXCPUUsagePlotController.class];
			
			[windowController _drainLayout];
			[windowController _drainLayout];
			[windowController _drainLayout];
			
			[__classToNameRNMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
				[self _createInstrumentScreenshotForPlotControllerClass:NSClassFromString(key) windowController:windowController inspectorPaneOverviewImage:inspectorPaneOverviewImage mapping:__classToNameRNMapping];
			}];
			
			[self _createRNBridgeDataBridgeDataScreenshotsForWindowController:windowController];
			[self _createRNAsyncStorageScreenshotsForWindowController:windowController];
			
			[windowController _drainLayout];
			[windowController close];
			[document close];
			[NSUserDefaults.standardUserDefaults synchronize];
			
			[NSUserDefaults.standardUserDefaults setBool:oldVal forKey:@"DTXPlotSettingsDisplayLabels"];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[NSUserDefaults.standardUserDefaults synchronize];
				exit(0);
			});
		}];
	}];
}

- (void)_createInstrumentScreenshotForPlotControllerClass:(Class)cls windowController:(DTXWindowController*)windowController inspectorPaneOverviewImage:(NSImage*)inspectorPaneOverviewImage mapping:(NSDictionary<NSString*, NSDictionary<NSString*, id>*>*) mapping;
{
	NSDictionary* info = mapping[NSStringFromClass(cls) ?: @"NULL"];
	NSBitmapImageRep* rep;
	if(cls != nil)
	{
		NSString* name = info[@"name"];
		NSArray* outlineBreadcrumbs = info[@"outlineBreadcrumbs"];
		NSInteger displaySample = 0;
		BOOL noSample = [info[@"displaySample"] isKindOfClass:NSNull.class];
		if(noSample == NO)
		{
			displaySample = [info[@"displaySample"] ?: __defaultSample integerValue];
		}
		NSInteger inspectorSample = [info[@"inspectorSample"] ?: (noSample == NO && info[@"displaySample"]) ? info[@"displaySample"] : __defaultSample integerValue];
		CGFloat scrollPercentage = [info[@"scrollPercentage"] ?: @0.5 doubleValue];
		BOOL lowkeyInspector = [info[@"lowkeyInspector"] boolValue];
		NSUInteger zoom = [info[@"zoom"] unsignedIntegerValue];
		
		[windowController _deselectAnyPlotControllers];
		if(noSample == NO)
		{
			[windowController _selectSampleAtIndex:displaySample forPlotControllerClass:cls];
		}
		
		for(NSUInteger idx = 0; idx < zoom; idx++)
		{
			[windowController zoomIn:nil];
		}
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForPlotControllerOfClass:cls].representations.firstObject;
		
		[[__DTXThemeBackgroundRep(rep) representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@.png", name]].path atomically:YES];
		
		[windowController _selectPlotControllerOfClass:cls];
		
		[windowController _deselectAnyDetail];

		[windowController _selectDetailPaneIndex:0];
		
		if(outlineBreadcrumbs)
		{
			[windowController _followOutlineBreadcrumbs:outlineBreadcrumbs forPlotControllerClass:cls selectLastBreadcrumb:NO];
		}
		
		[windowController _setBottomSplitAtPercentage:0.5];
		[windowController _scrollBottomPaneToPercentage:scrollPercentage];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
		
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane.png", name]].path atomically:YES];
		
		if(outlineBreadcrumbs)
		{
			[windowController _followOutlineBreadcrumbs:outlineBreadcrumbs forPlotControllerClass:cls selectLastBreadcrumb:YES];
		}
		else
		{
			[windowController _selectSampleAtIndex:inspectorSample forPlotControllerClass:cls];
		}
		
		[windowController _setBottomSplitAtPercentage:lowkeyInspector ? __inspectorLowkeyPercentage : __inspectorPercentage];
		[windowController _selectExtendedDetailInspector];
		
		rep = (NSBitmapImageRep*)[windowController _snapshotForInspectorPane].representations.firstObject;
		[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_InspectorPane.png", name]].path atomically:YES];
	}
	else
	{
		[windowController _selectProfilingInfoInspector];
		[windowController _setBottomSplitAtPercentage:__inspectorPercentage];
		
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

- (void)_createRNBridgeDataBridgeDataScreenshotsForWindowController:(DTXWindowController*)windowController
{
	NSBitmapImageRep* rep;
	
	Class cls = DTXRNBridgeDataTransferPlotController.class;
	NSString* name = @"RNBridgeData";
	
	[windowController _deselectAnyPlotControllers];
	[windowController _selectSampleAtIndex:[__defaultSample integerValue] forPlotControllerClass:cls];
	
	[windowController _selectPlotControllerOfClass:cls];
	
	[windowController _deselectAnyDetail];
	
	[windowController _setBottomSplitAtPercentage:0.5];
	[windowController _scrollBottomPaneToPercentage:0.5];
	
	[windowController _selectDetailPaneIndex:1];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
	
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane_BridgeData.png", name]].path atomically:YES];
	
	[windowController _selectDetailControllerSampleAtIndex:[__defaultSample integerValue]];
	
	[windowController _setBottomSplitAtPercentage:0.6];
	[windowController _selectExtendedDetailInspector];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForInspectorPane].representations.firstObject;
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_InspectorPane_BridgeData.png", name]].path atomically:YES];
}

- (void)_createRNAsyncStorageScreenshotsForWindowController:(DTXWindowController*)windowController
{
	NSBitmapImageRep* rep;
	
	Class cls = DTXRNAsyncStoragePlotController.class;
	NSString* name = @"RNAsyncStorage";
	
	[windowController _deselectAnyPlotControllers];
	[windowController _selectSampleAtIndex:[__defaultSample integerValue] forPlotControllerClass:cls];
	
	[windowController _selectPlotControllerOfClass:cls];
	
	[windowController _deselectAnyDetail];
	
	[windowController _setBottomSplitAtPercentage:0.5];
	[windowController _scrollBottomPaneToPercentage:0.5];
	
	[windowController _selectDetailPaneIndex:1];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
	
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane_Saves.png", name]].path atomically:YES];
}

- (void)_createEventsListScreenshotsForWindowController:(DTXWindowController*)windowController
{
	NSBitmapImageRep* rep;
	
	Class cls = DTXEventsPlotController.class;
	NSString* name = @"Events";
	
	[windowController _deselectAnyPlotControllers];
	[windowController _selectSampleAtIndex:[__defaultSample integerValue] forPlotControllerClass:cls];
	
	[windowController _selectPlotControllerOfClass:cls];
	
	[windowController _deselectAnyDetail];
	
	[windowController _setBottomSplitAtPercentage:0.5];
	[windowController _scrollBottomPaneToPercentage:0.5];
	
	[windowController _selectDetailPaneIndex:1];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
	
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane_List.png", name]].path atomically:YES];
}

- (void)_createActivityListScreenshotsForWindowController:(DTXWindowController*)windowController
{
	NSBitmapImageRep* rep;
	
	Class cls = DTXActivityPlotController.class;
	NSString* name = @"Activity";
	
	[windowController _deselectAnyPlotControllers];
	[windowController _selectSampleAtIndex:[__defaultSample integerValue] forPlotControllerClass:cls];
	
	[windowController _selectPlotControllerOfClass:cls];
	
	[windowController _deselectAnyDetail];
	
	[windowController _setBottomSplitAtPercentage:0.5];
	[windowController _scrollBottomPaneToPercentage:0.5];
	
	[windowController _selectDetailPaneIndex:1];
	
	rep = (NSBitmapImageRep*)[windowController _snapshotForDetailPane].representations.firstObject;
	
	[[rep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Instrument_%@_DetailPane_List.png", name]].path atomically:YES];
}

- (NSImage*)_exampleImageWithExistingRep:(NSBitmapImageRep*)rep
{
	const CGFloat exampleImageWidthPadding = 440;
	const CGFloat exampleImageHeightPadding = 100;
	const CGFloat exampleFontSize = 80;
	const CGFloat toolbarTitleXOffset = 1160;
	const CGFloat lineLength = 172;
	
	NSMutableParagraphStyle* pStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
	pStyle.alignment = NSTextAlignmentCenter;
	
	NSImage* exampleImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width + exampleImageWidthPadding * 2, rep.size.height + 1.5 * exampleImageHeightPadding)];
	[exampleImage lockFocus];
	
	[rep drawAtPoint:NSMakePoint(exampleImage.size.width / 2 - rep.size.width / 2, exampleImage.size.height / 2 - rep.size.height / 2 - exampleImageHeightPadding)];
	
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:@"Toolbar" attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:exampleFontSize weight:(NSFontWeightRegular + NSFontWeightThin) / 2.2], NSParagraphStyleAttributeName: pStyle}];
	[attr drawAtPoint:NSMakePoint(toolbarTitleXOffset, exampleImage.size.height - 10 - attr.size.height)];
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	
	path.lineWidth = 6;
	
	[path moveToPoint:NSMakePoint(toolbarTitleXOffset + attr.size.width / 2, exampleImage.size.height - 10 - attr.size.height - 10)];
	[path lineToPoint:NSMakePoint(toolbarTitleXOffset + attr.size.width / 2, exampleImage.size.height - 10 - attr.size.height - 10 - lineLength)];
	
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
	NSImage* toolbarImage = [[NSImage alloc] initWithSize:NSMakeSize(rep.size.width, 184)];
	[toolbarImage lockFocus];
	
	[rep drawAtPoint:NSMakePoint(0, toolbarImage.size.height - rep.size.height)];
	
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, toolbarImage.size}];
	[toolbarImage unlockFocus];
	[toolbarImage removeRepresentation:toolbarImage.representations.firstObject];
	[toolbarImage addRepresentation:rep];
	
	return toolbarImage;
}

- (NSImage*)_introImageWithRecordingWindowRep:(NSBitmapImageRep*)recWinRep managementWindowRep:(NSBitmapImageRep*)manageRep requestsPlaygroundRep:(NSBitmapImageRep*)requestsPlaygroundRep
{
	NSImage* introImage = [[NSImage alloc] initWithSize:NSMakeSize(recWinRep.size.width + manageRep.size.width / 4, recWinRep.size.height + manageRep.size.height / 5)];
	[introImage lockFocus];
	
	[recWinRep drawAtPoint:NSMakePoint(0, introImage.size.height - recWinRep.size.height)];
	[requestsPlaygroundRep drawInRect:(NSRect){NSMakePoint(introImage.size.width * 0.5 - requestsPlaygroundRep.size.width * 0.5, manageRep.size.height / 10), requestsPlaygroundRep.size} fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	[manageRep drawInRect:(NSRect){NSMakePoint(introImage.size.width - manageRep.size.width, 0), manageRep.size} fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	recWinRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, introImage.size}];
	[introImage unlockFocus];
	[introImage removeRepresentation:introImage.representations.firstObject];
	[introImage addRepresentation:recWinRep];
	
	return introImage;
}

- (NSImage*)_combineManagementImages:(NSBitmapImageRep*)first :(NSBitmapImageRep*)second :(NSBitmapImageRep*)third :(NSBitmapImageRep*)fourth :(NSBitmapImageRep*)fifth
{
	CGFloat mergedWidth = MAX(first.size.width + second.size.width, third.size.width + fourth.size.width);
	CGFloat mergedHeight = MAX(first.size.height, second.size.height) + MAX(third.size.height, fourth.size.height) + fifth.size.height;
	
	NSImage* mergedImage = [[NSImage alloc] initWithSize:NSMakeSize(mergedWidth, mergedHeight)];
	[mergedImage lockFocus];
	
	[first drawAtPoint:NSMakePoint(0, mergedHeight - (MAX(first.size.height, second.size.height) / 2 + first.size.height / 2))];
	[second drawAtPoint:NSMakePoint(first.size.width, mergedHeight - second.size.height)];
	
	[third drawAtPoint:NSMakePoint(0, mergedHeight - MAX(first.size.height, second.size.height) - third.size.height)];
	[fourth drawAtPoint:NSMakePoint(third.size.width, mergedHeight - MAX(first.size.height, second.size.height) - fourth.size.height)];
	
	[fifth drawAtPoint:NSMakePoint((mergedWidth / 2) - (fifth.size.width / 2), 0)];
	
//	[fifth drawInRect:(NSRect){(mergedWidth / 2) - (fifth.size.width / 2), (mergedHeight / 2) - (fifth.size.height / 2), fifth.size} fromRect:(NSRect){0,0,fifth.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	first = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, mergedImage.size}];
	[mergedImage unlockFocus];
	[mergedImage removeRepresentation:mergedImage.representations.firstObject];
	[mergedImage addRepresentation:first];
	
	return mergedImage;
}

- (void)_createConsoleMenuScreenshotWithWindowController:(DTXWindowController*)windowController
{
	DTXDebugMenuGenerator* menu = [DTXDebugMenuGenerator new];
	[[[NSNib alloc] initWithNibNamed:@"DTXDebugMenuGenerator" bundle:nil] instantiateWithOwner:menu topLevelObjects:nil];
	menu.visualEffectView.wantsLayer = YES;
	menu.visualEffectView.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.visualEffectView.layer.borderColor = [NSColor.windowFrameColor colorWithAlphaComponent:0.25].CGColor;
		menu.visualEffectView.layer.borderWidth = 1;
	}
	menu.visualEffectView.layer.masksToBounds = YES;
	
	menu.view.wantsLayer = YES;
	menu.view.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.view.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.85].CGColor;
	}
	else
	{
		menu.view.layer.borderColor = NSColor.lightGrayColor.CGColor;
	}
	menu.view.layer.borderWidth = 0.5;
	menu.view.layer.masksToBounds = YES;
	
	NSString* path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Console"];
	menu.secondImageView.image = [[NSWorkspace sharedWorkspace] iconForFile:path] ?: [NSImage imageNamed:@"console_small"];
	menu.secondImageView.image.size = NSMakeSize(16, 16);
	
	[windowController.window.contentView addSubview:menu.view];
	[windowController _drainLayout];
	
	NSBitmapImageRep* consoleMenuRep = (id)[menu.view snapshotForCachingDisplay].representations.firstObject;
	
	[menu.view removeFromSuperview];
	
	NSImage* consoleMenuImage = [[NSImage alloc] initWithSize:NSMakeSize(858, 82)];
	[consoleMenuImage lockFocus];
	
	NSShadow* shadow = [NSShadow new];
	shadow.shadowOffset = NSMakeSize(0, -4);
	shadow.shadowBlurRadius = 16.0;
	shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent:0.25];
	[shadow set];
	
	NSRect centered = (NSRect){93, 20, consoleMenuRep.size};
	[consoleMenuRep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	consoleMenuRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, consoleMenuImage.size}];
	
	[consoleMenuImage unlockFocus];
	
	[[consoleMenuRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"RecordingDocument_DetailPane_Console.png"].path atomically:YES];
}

- (void)_createBridgeDataMenuScreenshotWithWindowController:(DTXWindowController*)windowController
{
	DTXDebugMenuGenerator* menu = [DTXDebugMenuGenerator new];
	[[[NSNib alloc] initWithNibNamed:@"DTXDebugMenuGenerator" bundle:nil] instantiateWithOwner:menu topLevelObjects:nil];
	menu.visualEffectView.wantsLayer = YES;
	menu.visualEffectView.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.visualEffectView.layer.borderColor = [NSColor.windowFrameColor colorWithAlphaComponent:0.25].CGColor;
		menu.visualEffectView.layer.borderWidth = 1;
	}
	menu.visualEffectView.layer.masksToBounds = YES;
	
	menu.view.wantsLayer = YES;
	menu.view.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.view.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.85].CGColor;
	}
	else
	{
		menu.view.layer.borderColor = NSColor.lightGrayColor.CGColor;
	}
	menu.view.layer.borderWidth = 0.5;
	menu.view.layer.masksToBounds = YES;
	
	menu.firstImageTextField.stringValue = @"Samples";
	menu.firstImageView.image = [NSImage imageNamed:@"samples"];
	menu.firstImageView.image.size = NSMakeSize(16, 16);
	menu.secondImageTextField.stringValue = @"Bridge Data";
	menu.secondImageView.image = [NSImage imageNamed:@"bridge_data"];
	menu.secondImageView.image.size = NSMakeSize(16, 16);
	
	if(NSApp.effectiveAppearance.isDarkAppearance == NO)
	{
		menu.secondImageView.contentTintColor = NSColor.whiteColor;
	}
	
	menu.chevronImageView.hidden = YES;
	
	[windowController.window.contentView addSubview:menu.view];
	[windowController _drainLayout];
	
	NSBitmapImageRep* consoleMenuRep = (id)[menu.view snapshotForCachingDisplay].representations.firstObject;
	
	[menu.view removeFromSuperview];
	
	NSImage* consoleMenuImage = [[NSImage alloc] initWithSize:NSMakeSize(858, 82)];
	[consoleMenuImage lockFocus];
	
	NSShadow* shadow = [NSShadow new];
	shadow.shadowOffset = NSMakeSize(0, -4);
	shadow.shadowBlurRadius = 16.0;
	shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent:0.25];
	[shadow set];
	
	NSRect centered = (NSRect){93, 20, consoleMenuRep.size};
	[consoleMenuRep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	consoleMenuRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, consoleMenuImage.size}];
	
	[consoleMenuImage unlockFocus];
	
	[[consoleMenuRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Instrument_RNBridgeData_Menu.png"].path atomically:YES];
}

- (void)_createAsyncStorageMenuScreenshotWithWindowController:(DTXWindowController*)windowController
{
	DTXDebugMenuGenerator* menu = [DTXDebugMenuGenerator new];
	[[[NSNib alloc] initWithNibNamed:@"DTXDebugMenuGenerator" bundle:nil] instantiateWithOwner:menu topLevelObjects:nil];
	menu.visualEffectView.wantsLayer = YES;
	menu.visualEffectView.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.visualEffectView.layer.borderColor = [NSColor.windowFrameColor colorWithAlphaComponent:0.25].CGColor;
		menu.visualEffectView.layer.borderWidth = 1;
	}
	menu.visualEffectView.layer.masksToBounds = YES;
	
	menu.view.wantsLayer = YES;
	menu.view.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.view.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.85].CGColor;
	}
	else
	{
		menu.view.layer.borderColor = NSColor.lightGrayColor.CGColor;
	}
	menu.view.layer.borderWidth = 0.5;
	menu.view.layer.masksToBounds = YES;
	
	menu.firstImageTextField.stringValue = @"Fetches";
	menu.firstImageView.image = [NSImage imageNamed:@"RNAsyncStorageFetches"];
	menu.firstImageView.image.size = NSMakeSize(16, 16);
	menu.secondImageTextField.stringValue = @"Saves";
	menu.secondImageView.image = [NSImage imageNamed:@"RNAsyncStorageSaves"];
	menu.secondImageView.image.size = NSMakeSize(16, 16);
	
	if(NSApp.effectiveAppearance.isDarkAppearance == NO)
	{
		menu.secondImageView.contentTintColor = NSColor.whiteColor;
	}
	
	menu.chevronImageView.hidden = YES;
	
	[windowController.window.contentView addSubview:menu.view];
	[windowController _drainLayout];
	
	NSBitmapImageRep* consoleMenuRep = (id)[menu.view snapshotForCachingDisplay].representations.firstObject;
	
	[menu.view removeFromSuperview];
	
	NSImage* consoleMenuImage = [[NSImage alloc] initWithSize:NSMakeSize(858, 82)];
	[consoleMenuImage lockFocus];
	
	NSShadow* shadow = [NSShadow new];
	shadow.shadowOffset = NSMakeSize(0, -4);
	shadow.shadowBlurRadius = 16.0;
	shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent:0.25];
	[shadow set];
	
	NSRect centered = (NSRect){93, 20, consoleMenuRep.size};
	[consoleMenuRep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	consoleMenuRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, consoleMenuImage.size}];
	
	[consoleMenuImage unlockFocus];
	
	[[consoleMenuRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Instrument_RNAsyncStorage_Menu.png"].path atomically:YES];
}

- (void)_createEventsDetailMenuScreenshotWithWindowController:(DTXWindowController*)windowController
{
	DTXDebugMenuGenerator* menu = [DTXDebugMenuGenerator new];
	[[[NSNib alloc] initWithNibNamed:@"DTXDebugMenuGenerator" bundle:nil] instantiateWithOwner:menu topLevelObjects:nil];
	menu.visualEffectView.wantsLayer = YES;
	menu.visualEffectView.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.visualEffectView.layer.borderColor = [NSColor.windowFrameColor colorWithAlphaComponent:0.25].CGColor;
		menu.visualEffectView.layer.borderWidth = 1;
	}
	menu.visualEffectView.layer.masksToBounds = YES;
	
	menu.view.wantsLayer = YES;
	menu.view.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.view.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.85].CGColor;
	}
	else
	{
		menu.view.layer.borderColor = NSColor.lightGrayColor.CGColor;
	}
	menu.view.layer.borderWidth = 0.5;
	menu.view.layer.masksToBounds = YES;
	
	menu.firstImageTextField.stringValue = @"Summary";
	menu.firstImageView.image = [NSImage imageNamed:@"samples_nonflat"];
	menu.firstImageView.image.size = NSMakeSize(16, 16);
	menu.secondImageTextField.stringValue = @"List";
	menu.secondImageView.image = [NSImage imageNamed:@"samples"];
	menu.secondImageView.image.size = NSMakeSize(16, 16);
	
	if(NSApp.effectiveAppearance.isDarkAppearance == NO)
	{
		menu.secondImageView.contentTintColor = NSColor.whiteColor;
	}
	
	menu.chevronImageView.hidden = YES;
	
	[windowController.window.contentView addSubview:menu.view];
	[windowController _drainLayout];
	
	NSBitmapImageRep* consoleMenuRep = (id)[menu.view snapshotForCachingDisplay].representations.firstObject;
	
	[menu.view removeFromSuperview];
	
	NSImage* consoleMenuImage = [[NSImage alloc] initWithSize:NSMakeSize(858, 82)];
	[consoleMenuImage lockFocus];
	
	NSShadow* shadow = [NSShadow new];
	shadow.shadowOffset = NSMakeSize(0, -4);
	shadow.shadowBlurRadius = 16.0;
	shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent:0.25];
	[shadow set];
	
	NSRect centered = (NSRect){93, 20, consoleMenuRep.size};
	[consoleMenuRep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	consoleMenuRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, consoleMenuImage.size}];
	
	[consoleMenuImage unlockFocus];
	
	[[consoleMenuRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"Instrument_Events_Menu.png"].path atomically:YES];
}

- (void)_createAppLaunchProfileMenuScreenshotWithWindowController:(DTXWindowController*)windowController
{
	DTXDebugMenuGenerator* menu = [DTXDebugMenuGenerator new];
	[[[NSNib alloc] initWithNibNamed:@"DTXDebugMenuNoIconsGenerator" bundle:nil] instantiateWithOwner:menu topLevelObjects:nil];
	menu.visualEffectView.wantsLayer = YES;
	menu.visualEffectView.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.visualEffectView.layer.borderColor = [NSColor.windowFrameColor colorWithAlphaComponent:0.25].CGColor;
		menu.visualEffectView.layer.borderWidth = 1;
	}
	menu.visualEffectView.layer.masksToBounds = YES;
	
	menu.view.wantsLayer = YES;
	menu.view.layer.cornerRadius = 5.0;
	if(NSApp.effectiveAppearance.isDarkAppearance)
	{
		menu.view.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.85].CGColor;
	}
	else
	{
		menu.view.layer.borderColor = NSColor.lightGrayColor.CGColor;
	}
	menu.view.layer.borderWidth = 0.5;
	menu.view.layer.masksToBounds = YES;
	
	menu.firstImageTextField.stringValue = @"Profile";
	menu.secondImageTextField.stringValue = @"App Launch";
	
	[windowController.window.contentView addSubview:menu.view];
	[windowController _drainLayout];
	
	[menu.view setFrame:(NSRect){0, 0, 109, 50}];
	
	NSBitmapImageRep* consoleMenuRep = (id)[menu.view snapshotForCachingDisplay].representations.firstObject;
	
	[menu.view removeFromSuperview];
	
	NSImage* consoleMenuImage = [[NSImage alloc] initWithSize:NSMakeSize(858, 82)];
	[consoleMenuImage lockFocus];
	
	NSShadow* shadow = [NSShadow new];
	shadow.shadowOffset = NSMakeSize(0, -4);
	shadow.shadowBlurRadius = 16.0;
	shadow.shadowColor = [NSColor.blackColor colorWithAlphaComponent:0.25];
	[shadow set];
	
	NSRect centered = (NSRect){93, 20, consoleMenuRep.size};
	[consoleMenuRep drawInRect:centered fromRect:(NSRect){0, 0, centered.size} operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	consoleMenuRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(NSRect){0, 0, consoleMenuImage.size}];
	
	[consoleMenuImage unlockFocus];
	
	[[consoleMenuRep representationUsingType:NSPNGFileType properties:@{}] writeToFile:[self._resourcesURL URLByAppendingPathComponent:@"AppLaunch_AppLaunchProfilingMenu.png"].path atomically:YES];
}

- (NSImage*)_snapshotForGeneralFromPrefs:(DTXInstrumentsPreferencesWindowController*)prefs
{
	[prefs _drainLayout];
	[prefs _drainLayout];
	
	[prefs _activateControllerAtIndex:0];
	
	[prefs _drainLayout];
	[prefs _drainLayout];
	
	return [prefs.window snapshotForCachingDisplay];
}

- (NSImage*)_snapshotForCLIFromPrefs:(DTXInstrumentsPreferencesWindowController*)prefs
{
	[prefs _drainLayout];
	[prefs _drainLayout];
	
	[prefs _activateControllerAtIndex:2];
	
	[prefs _drainLayout];
	[prefs _drainLayout];
	
	return [prefs.window snapshotForCachingDisplay];
}

- (NSImage*)_snapshotForRecordingSettingsFromPrefs:(DTXInstrumentsPreferencesWindowController*)prefs
{
	[prefs _drainLayout];
	[prefs _drainLayout];

	[prefs _activateControllerAtIndex:1];
	
	[prefs _drainLayout];
	[prefs _drainLayout];

	return [prefs.window snapshotForCachingDisplay];
}

- (NSImage*)_snapshotForIgnoredCategoriesFromPrefs:(DTXInstrumentsPreferencesWindowController*)prefs
{
	NSArray* oldCategories = [NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
	[NSUserDefaults.standardUserDefaults setObject:@[@"FirstIgnoredCategory", @"SecondIgnoredCategory"] forKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
	
	[prefs _drainLayout];
	[prefs _drainLayout];
	
	[prefs _activateControllerAtIndex:1];
	
	NSViewController* targetPicker = [prefs valueForKey:@"_activeViewController"];
	[targetPicker performSegueWithIdentifier:@"PresentIgnoredCategoriesSegue" sender:nil];

	[prefs _drainLayout];
	[prefs _drainLayout];

	NSWindow* window = prefs.window.sheets.firstObject;
	auto rv = [window snapshotForCachingDisplay];
	
	[NSUserDefaults.standardUserDefaults setObject:oldCategories forKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
	
	return rv;
}

@end

#endif
