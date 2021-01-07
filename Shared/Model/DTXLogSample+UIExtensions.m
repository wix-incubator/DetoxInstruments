//
//  DTXLogSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXLogSample+UIExtensions.h"

NSColor* DTXLogLevelColor(DTXProfilerLogLevel logLevel)
{
	switch(logLevel) {
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

NSString* DTXLogLevelDescription(DTXProfilerLogLevel logLevel, BOOL extended)
{
	if(extended)
	{
		switch(logLevel) {
			case DTXProfilerLogLevelNotice:
				return NSLocalizedString(@"Notice", @"");
			default:
				break;
		}
	}
	
	switch(logLevel) {
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

@implementation DTXLogSample (UIExtensions)

- (NSColor *)colorForLogLevel
{
	return DTXLogLevelColor(self.level);
}

- (NSString*)logLevelDescription
{
	return DTXLogLevelDescription(self.level, NO);
}

@end
