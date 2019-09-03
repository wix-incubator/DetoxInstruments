//
//  DTXCPUInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXCPUInspectorDataProvider.h"
#import "DTXPieChartView.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXThreadInfo+UIExtensions.h"
#import "NSColor+UIAdditions.h"
#import "NSAppearance+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"

@implementation DTXCPUInspectorDataProvider

- (NSArray *)arrayForStackTrace
{
	return [(DTXPerformanceSample*)self.sample heaviestStackTrace];
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
					  @"UIKitCore": @"DBGFrameAppKit",
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
					  @"QuartzCore": @"DBGFrameGraphics",
				  
					  @"WebCore": @"DBGFrameWeb",
					  @"JavaScriptCore": @"DBGFrameWeb",
					  @"DTX_JSC": @"DBGFrameWeb",
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
		
		if([self.document.firstRecording.appName isEqualToString:symbolImage])
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

- (DTXInspectorContent*)_inspectorContentForThreads
{
	DTXInspectorContent* stackTrace = [DTXInspectorContent new];
	
	NSMutableArray<DTXStackTraceFrame*>* stackFrames = [NSMutableArray new];
	NSMutableParagraphStyle* par = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
	par.lineBreakMode = NSLineBreakByTruncatingTail;
	par.paragraphSpacing = 5.0;
	par.allowsDefaultTighteningForTruncation = NO;
	
	DTXPerformanceSample* perfSample = self.sample;
	
	NSArray* arrayForStackTrace = self.arrayForStackTrace;
	if(arrayForStackTrace.count == 0)
	{
		arrayForStackTrace = @[@"<No Stack Trace>"];
	}
	
	NSMutableOrderedSet* threadSamples = perfSample.threadSamples.mutableCopy;
	[threadSamples sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"cpuUsage" ascending:NO]]];
	
	
	__block BOOL hasMore;
	[threadSamples enumerateObjectsUsingBlock:^(DTXThreadPerformanceSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(idx > 0 && obj.threadInfo.number != 0 && ((obj.cpuUsage < 0.1 && idx >= 10) || obj.cpuUsage < 0.005))
		{
			hasMore = YES;
			return;
		}
		
		DTXStackTraceFrame* frame = [DTXStackTraceFrame new];
		frame.stackFrameText = [[NSAttributedString alloc] initWithString:obj.threadInfo.friendlyName attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
		frame.stackFrameDetailText = [[NSAttributedString alloc] initWithString:[NSFormatter.dtx_percentFormatter stringFromNumber:@(obj.cpuUsage)] attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
		frame.stackFrameIcon = [NSImage imageNamed:@"color_indicator"];
		frame.imageTintColor = [NSColor randomColorWithSeed:obj.threadInfo.friendlyName];
		
		[stackFrames addObject:frame];
	}];
	
	if(hasMore == YES)
	{
		DTXStackTraceFrame* frame = [DTXStackTraceFrame new];
		frame.stackFrameText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"(%@ %@)", @(threadSamples.count - stackFrames.count), NSLocalizedString(@"more threads", @"")] attributes:@{NSParagraphStyleAttributeName: par, NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
		frame.stackFrameIcon = [NSImage imageNamed:@"color_indicator"];
		frame.imageTintColor = NSColor.clearColor;
		[stackFrames addObject:frame];
	}
	
	stackTrace.stackFrames = stackFrames;
	stackTrace.selectionDisabled = YES;
	
	return stackTrace;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	__kindof DTXPerformanceSample* perfSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = perfSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Total CPU Usage", @"") description:[NSFormatter.dtx_percentFormatter stringForObjectValue:@(perfSample.cpuUsage)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Active CPU Cores", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(self.document.firstRecording.deviceProcessorCount)]]];
	
	request.content = content;
	
	NSMutableArray<DTXInspectorContent*>* contentArray = @[request].mutableCopy;
	
	DTXPerformanceSample* sample = (id)perfSample;
	
	__block DTXThreadInfo* heaviestThread;
	
	if(self.document.firstRecording.dtx_profilingConfiguration.recordThreadInformation && sample.threadSamples.count > 0)
	{
		DTXPieChartView* pieChartView = [DTXPieChartView new];
		NSMutableArray<DTXPieChartEntry*>* entries = NSMutableArray.new;
		
		NSMutableOrderedSet* threadSamples = sample.threadSamples.mutableCopy;
//		[threadSamples filterUsingPredicate:[NSPredicate predicateWithFormat:@"cpuUsage > 0"]];
//		[threadSamples sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"cpuUsage" ascending:NO]]];
		
		__block NSUInteger heaviestThreadIdx = 0;
		__block double heaviestCPU = -1;
		
		[threadSamples enumerateObjectsUsingBlock:^(DTXThreadPerformanceSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if(obj.cpuUsage > heaviestCPU)
			{
				heaviestThreadIdx = idx;
				heaviestCPU = obj.cpuUsage;
				heaviestThread = obj.threadInfo;
			}
			
			[entries addObject:[DTXPieChartEntry entryWithValue:@(obj.cpuUsage > 0 ? obj.cpuUsage : 0.0001) title:obj.threadInfo.friendlyName color:nil]];
		}];
		
		[pieChartView setEntries:entries highlightedEntry:heaviestThreadIdx];
		
		pieChartView.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[
			[pieChartView.heightAnchor constraintEqualToConstant:200],
		]];
		
		DTXInspectorContent* pieChartContent = [DTXInspectorContent new];
		pieChartContent.title = NSLocalizedString(@"Threads Breakdown", @"");
		pieChartContent.customView = pieChartView;
		
		[contentArray addObject:pieChartContent];
		
		DTXInspectorContent* threads = [self _inspectorContentForThreads];
		threads.title = NSLocalizedString(@"Threads", @"");
		
		[contentArray addObject:threads];
	}
	
	if(self.document.firstRecording.dtx_profilingConfiguration.collectStackTraces && [perfSample threadSamples].count > 0)
	{
		DTXInspectorContent* stackTrace = [self inspectorContentForStackTrace];
		stackTrace.title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Heaviest Stack Trace", @""), heaviestThread.friendlyName];
		
		[contentArray addObject:stackTrace];
	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

- (BOOL)canCopy
{
	return [self.sample isKindOfClass:[DTXPerformanceSample class]];
}

@end
