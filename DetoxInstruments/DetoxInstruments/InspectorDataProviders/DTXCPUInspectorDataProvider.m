//
//  DTXCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUInspectorDataProvider.h"
#import "DTXPieChartView.h"
#import "DTXRecording+UIExtensions.h"

@implementation DTXCPUInspectorDataProvider

- (NSArray *)arrayForStackTrace
{
	return [(DTXAdvancedPerformanceSample*)self.sample heaviestStackTrace];
}

- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	NSString* stackTraceFrame = nil;
	
	if([obj isKindOfClass:[NSNumber class]] == YES)
	{
		stackTraceFrame = [NSString stringWithFormat:@"%p", (void*)[obj unsignedIntegerValue]];
	}
	else if([obj isKindOfClass:[NSString class]] == YES)
	{
		stackTraceFrame = obj;
	}
	else if([obj isKindOfClass:[NSDictionary class]] == YES)
	{
		if(fullFormat)
		{
			stackTraceFrame = [NSString stringWithFormat:@"%-35s 0x%016llx %@ + %@", [obj[@"image"] UTF8String], (uint64_t)[(obj[@"address"] ?: @0) unsignedIntegerValue], obj[@"symbol"], obj[@"offset"]];
		}
		else
		{
			stackTraceFrame = [NSString stringWithFormat:@"%@ + %@", obj[@"symbol"], obj[@"offset"]];
		}
	}
	
	return stackTraceFrame;
}

- (NSImage*)imageForObject:(id)obj
{
	static NSDictionary<NSString*, NSString*>* _iconMaps;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		_iconMaps = @{@"DTXProfiler": @"DBGFrameFrameworks",
					  
					  @"???": @"DBGFrameGeneric",
					  
					  @"UIKit": @"DBGFrameAppKit",
					  @"UserNotificationsUI": @"DBGFrameAppKit",
					  @"AssetsLibrary": @"DBGFrameAppKit",
					  @"MessageUI": @"DBGFrameAppKit",
					  @"ContactsUI": @"DBGFrameAppKit",
					  @"WatchKit": @"DBGFrameAppKit",
					  @"EventKitUI": @"DBGFrameAppKit",
					  @"MapKit": @"DBGFrameAppKit",
					  @"LocalAuthentication": @"DBGFrameAppKit",
					  @"PhotosUI": @"DBGFrameAppKit",
					  @"WatchConnectivity": @"DBGFrameAppKit",
					  @"IntentsUI": @"DBGFrameAppKit",
					  @"HealthKitUI": @"DBGFrameAppKit",
					  @"SpriteKit": @"DBGFrameAppKit",
					  @"AddressBookUI": @"DBGFrameAppKit",
					  @"MediaPlayer": @"DBGFrameAppKit",
					  @"QuickLook": @"DBGFrameAppKit",
					  @"FileProviderUI": @"DBGFrameAppKit",
					  
					  @"CoreFoundation": @"DBGFrameFoundation",
					  @"Foundation": @"DBGFrameFoundation",
					  
					  @"CoreGraphics": @"DBGFrameGraphics",
					  @"GraphicsServices": @"DBGFrameGraphics",
					  @"ARKit": @"DBGFrameGraphics",
					  @"MetalKit.framework": @"DBGFrameGraphics",
					  @"MetalPerformanceShaders": @"DBGFrameGraphics",
				  
					  @"WebCore": @"DBGFrameWeb",
					  @"JavaScriptCore": @"DBGFrameWeb",
					  @"WebKit": @"DBGFrameWeb",
					  @"WebKitLegacy": @"DBGFrameWeb",
					  @"WebUI": @"DBGFrameWeb",
					  
					  @"libobjc.A.dylib": @"DBGFrameLanguages",
					  
					  @"libdyld.dylib": @"DBGFrameSystem",
					  @"libdispatch.dylib": @"DBGFrameSystem",
					  @"System.framework": @"DBGFrameSystem",
					  
					  @"CoreData": @"DBGFrameDatabase",
					  
					  @"AVFoundation": @"DBGFrameAudioSpeech",
					  @"AVKit": @"DBGFrameAudioSpeech",
					  @"AudioToolbox": @"DBGFrameAudioSpeech",
					  
					  @"MultipeerConnectivity": @"DBGFrameNetworkIO",
					  @"NetworkExtension": @"DBGFrameNetworkIO",
					  @"CFNetwork": @"DBGFrameNetworkIO",
					  
					  @"Security": @"DBGFrameSecurity",
					  };
	});
	
	NSString* imageName = @"DBGFrameFrameworks";
	
	if([obj isKindOfClass:[NSDictionary class]])
	{
		NSString* symbolImage = obj[@"image"];
		
		if([self.document.recording.appName isEqualToString:symbolImage])
		{
			imageName = @"DBGFrameUser";
		}
		else
		{
			if([symbolImage hasPrefix:@"libsystem"])
			{
				imageName = @"DBGFrameSystem";
			}
			else if([symbolImage hasPrefix:@"libsqlite"])
			{
				imageName = @"DBGFrameDatabase";
			}
			
			imageName = _iconMaps[obj[@"image"]] ?: imageName;
		}
	}
	
	return [NSImage imageNamed:imageName];
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	__kindof DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Active CPU Cores", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(self.document.recording.deviceProcessorCount)]]];
	
	request.content = content;
	
//	DTXPieChartView* pieChartView = [[DTXPieChartView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
//
//	pieChartView.entries = @[[DTXPieChartEntry entryWithValue:@10 title:nil color:NSColor.redColor], [DTXPieChartEntry entryWithValue:@20 title:nil color:NSColor.greenColor], [DTXPieChartEntry entryWithValue:@30 title:nil color:NSColor.blueColor]];
//
//	pieChartView.translatesAutoresizingMaskIntoConstraints = NO;
//	[NSLayoutConstraint activateConstraints:@[[pieChartView.widthAnchor constraintEqualToConstant:300], [pieChartView.heightAnchor constraintEqualToConstant:300]]];
//
//	DTXInspectorContent* pieChartContent = [DTXInspectorContent new];
//	pieChartContent.title = @"Pie Chart";
//	pieChartContent.customView = pieChartView;
	
	if(perfSample.recording.dtx_profilingConfiguration.collectStackTraces)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = NSLocalizedString(@"Heaviest Stack Trace", @"");
		
		rv.contentArray = @[request, stackTrace];
	}
	else
	{
		rv.contentArray = @[request];
	}
	
	return rv;
}

- (BOOL)canCopy
{
	return [self.sample isKindOfClass:[DTXAdvancedPerformanceSample class]];
}

@end
