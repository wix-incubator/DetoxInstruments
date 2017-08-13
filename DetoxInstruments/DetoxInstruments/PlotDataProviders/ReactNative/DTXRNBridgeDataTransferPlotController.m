//
//  DTXRNBridgeDataTransferPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRNBridgeDataTransferPlotController.h"
#import "DTXRNBridgeDataDataProvider.h"

@implementation DTXRNBridgeDataTransferPlotController

+ (Class)UIDataProviderClass
{
	return [DTXRNBridgeDataDataProvider class];
}

- (Class)classForPerformanceSamples
{
	return [DTXReactNativePeroformanceSample class];
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Bridge Data", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"bridgeData"];
}

- (NSImage *)secondaryIcon
{
	return [NSImage imageNamed:@"react"];
}

+ (NSArray<NSString*>*)sampleKeys
{
	return @[@"bridgeNToJSDataSizeDelta", @"bridgeJSToNDataSizeDelta"];
}

+ (NSArray<NSColor*>*)plotColors
{
#if __MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_12_4
	return @[[NSColor.systemPurpleColor colorWithAlphaComponent:1.0], [NSColor.systemOrangeColor colorWithAlphaComponent:1.0]];
#else
	return @[[NSColor.purpleColor colorWithAlphaComponent:1.0], [NSColor.orangeColor colorWithAlphaComponent:1.0]];
#endif
}

+ (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"JavaScript to Native", @""), NSLocalizedString(@"Native to JavaScript", @"")];
}

+ (BOOL)isStepped
{
	return YES;
}

+ (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

@end
