//
//  DTXCPUUsageDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXCPUUsageDataExporter.h"
#import "DTXThreadInfo+UIExtensions.h"
#import "DTXRecording+Additions.h"

@implementation DTXCPUUsageDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	if(self.document.firstRecording.dtx_profilingConfiguration.recordThreadInformation)
	{
		return @[@"timestamp", @"cpuUsage", @"heaviestThreadName", @"threadSamples.@max.cpuUsage"];
	}
	else
	{
		return @[@"timestamp", @"cpuUsage"];
	}
}

- (NSArray<NSString *> *)titles
{
	if(self.document.firstRecording.dtx_profilingConfiguration.recordThreadInformation)
	{
		return @[@"Time", @"CPU Usage", @"Heaviest Thread Name", @"Heaviest Thread CPU Usage"];
	}
	else
	{
		return @[@"Time", @"CPU Usage"];
	}
}

@end
