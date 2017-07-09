//
//  DTXNetworkInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkInspectorDataProvider.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import <CoreServices/CoreServices.h>

@implementation DTXNetworkInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	NSMutableArray* contentArray = [NSMutableArray new];
	
	DTXNetworkSample* networkSample = self.sample;
	
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Request", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = networkSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"URL", @"") description:networkSample.url]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"HTTP Method", @"") description:networkSample.requestHTTPMethod]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Size", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(networkSample.requestDataLength)]]];
	
	request.content = content;
	
	DTXInspectorContent* requestHeaders = [DTXInspectorContent new];
	requestHeaders.title = NSLocalizedString(@"Request Headers", @"");
	
	content = [NSMutableArray new];
	
	[[networkSample.requestHeaders.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:networkSample.requestHeaders[key]]];
	}];
	
	requestHeaders.content = content;
	
	DTXInspectorContent* response = [DTXInspectorContent new];
	response.title = NSLocalizedString(@"Response", @"");
	
	content = [NSMutableArray new];
	
	if(networkSample.responseTimestamp == nil || networkSample.responseStatusCode == 0)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:@"--"]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Status", @"") description:NSLocalizedString(@"Pending", @"") color:NSColor.warning3Color]];
		response.content = content;
		
		[contentArray addObject:response];
	}
	else
	{
		ti = networkSample.responseTimestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
		
		NSString* status = [NSString stringWithFormat:@"%@%@", @(networkSample.responseStatusCode), networkSample.responseStatusCodeString ? [NSString stringWithFormat:@" (%@)", networkSample.responseStatusCodeString] : @""];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Status", @"") description:status color:networkSample.responseStatusCode < 200 || networkSample.responseStatusCode >= 400 ? NSColor.warning3Color : NSColor.textColor]];
		if(networkSample.responseError != nil)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Error", @"") description:networkSample.responseError]];
		}
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Size", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(networkSample.responseDataLength)]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"MIME Type", @"") description:networkSample.responseMIMEType]];
		
		response.content = content;
		
		[contentArray addObject:response];
		
		DTXInspectorContent* responseHeaders = [DTXInspectorContent new];
		responseHeaders.title = NSLocalizedString(@"Response Headers", @"");
		
		content = [NSMutableArray new];
		
		[[networkSample.responseHeaders.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:networkSample.responseHeaders[key]]];
		}];
		
		responseHeaders.content = content;
		
		[contentArray addObject:responseHeaders];
	}
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)networkSample.responseMIMEType, NULL);
	
	if(UTTypeConformsTo(UTI, kUTTypeImage))
	{
		NSImage* image = [[NSImage alloc] initWithData:networkSample.responseData.data];
		DTXInspectorContent* responsePreview = [DTXInspectorContent new];
		responsePreview.title = NSLocalizedString(@"Preview", @"");
		responsePreview.image = image;
		
		[contentArray addObject:responsePreview];
	}
	
	if(UTI != NULL)
	{
		CFRelease(UTI);
	}
	
	[contentArray addObject:request];
	[contentArray addObject:requestHeaders];
	
	rv.contentArray = contentArray;
	
	return rv;
}

@end
