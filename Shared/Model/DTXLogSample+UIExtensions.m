//
//  DTXLogSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXLogSample+UIExtensions.h"
#import "DTXProfilerLogLevel.h"

@implementation DTXLogSample (UIExtensions)

- (NSColor *)colorForLogLevel
{
	switch(self.level) {
		case DTXProfilerLogLevelDebug:
			return NSColor.grayColor;
		case DTXProfilerLogLevelInfo:
			return NSColor.lightGrayColor;
		case DTXProfilerLogLevelError:
			return NSColor.systemYellowColor;
		case DTXProfilerLogLevelFault:
			return NSColor.systemRedColor;
		default:
			return nil;
	}
}

- (NSString*)logLevelDescription
{
	switch(self.level) {
		case DTXProfilerLogLevelDebug:
			return NSLocalizedString(@"Debug", @"");
		case DTXProfilerLogLevelInfo:
			return NSLocalizedString(@"Info", @"");
		case DTXProfilerLogLevelError:
			return NSLocalizedString(@"Error", @"");
		case DTXProfilerLogLevelFault:
			return NSLocalizedString(@"Fault", @"");
		default:
			return nil;
	}
}

@end
