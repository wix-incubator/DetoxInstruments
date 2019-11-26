//
//  DTXNetworkDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXNetworkDataProvider.h"
#import "DTXNetworkInspectorDataProvider.h"
#import "DTXNetworkDataExporter.h"

@implementation DTXNetworkDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXNetworkInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXNetworkDataExporter.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* duration = [DTXColumnInformation new];
	duration.title = NSLocalizedString(@"Duration", @"");
	duration.minWidth = 90;
	duration.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:YES];
	
	DTXColumnInformation* size = [DTXColumnInformation new];
	size.title = NSLocalizedString(@"Transferred", @"");
	size.minWidth = 70;
	size.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"totalDataLength" ascending:YES];
	
	DTXColumnInformation* responseCode = [DTXColumnInformation new];
	responseCode.title = NSLocalizedString(@"Status Code", @"");
	responseCode.minWidth = 70;
	responseCode.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"responseStatusCode" ascending:YES];
	
	DTXColumnInformation* url = [DTXColumnInformation new];
	url.title = NSLocalizedString(@"URL", @"");
//	url.minWidth = 355;
	url.automaticallyGrowsWithTable = YES;
	url.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"url" ascending:YES];
	
	return @[duration, size, responseCode, url];
}

- (Class)sampleClass
{
	return DTXNetworkSample.class;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	DTXNetworkSample* networkSample = item;
	
	switch(column)
	{
		case 0:
			if(networkSample.responseTimestamp == nil)
			{
				return @" ";
			}
			return [[NSFormatter dtx_durationFormatter] stringFromDate:networkSample.timestamp toDate:networkSample.responseTimestamp];
		case 1:
			if(networkSample.responseTimestamp == nil)
			{
				return @" ";
			}
			return [[NSFormatter dtx_memoryFormatter] stringForObjectValue:@(networkSample.totalDataLength)];
		case 2:
			if(networkSample.responseTimestamp == nil)
			{
				return @" ";
			}
			return [[NSFormatter dtx_stringFormatter] stringForObjectValue:@(networkSample.responseStatusCode)];
		case 3:
			return networkSample.url;
		default:
			return @" ";
	}
}

- (NSColor *)backgroundRowColorForItem:(id)item
{
	DTXNetworkSample* sample = item;
	
	if(sample.responseError.length > 0)
	{
		return NSColor.warning3Color;
	}
	
	if(sample.responseStatusCode == 0)
	{
		return NSColor.warningColor;
	}
	else if(sample.responseStatusCode < 200 || sample.responseStatusCode >= 400)
	{
		return NSColor.warning2Color;
	}
	
	return NSColor.successColor;
}

- (NSString*)statusTooltipforItem:(id)item
{
	DTXNetworkSample* sample = item;
	
	if(sample.responseError.length > 0)
	{
		return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Error:", @""), sample.responseError];
	}
	
	if(sample.responseStatusCode == 0)
	{
		return NSLocalizedString(@"Incomplete request", @"");
	}
	else if(sample.responseStatusCode < 200 || sample.responseStatusCode >= 400)
	{
		return [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"HTTP error", @""), @(sample.responseStatusCode)];
	}
	
	return [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"Success", @""), @(sample.responseStatusCode)];
}

- (BOOL)supportsDataFiltering
{
	return YES;
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[@"url", @"responseStatusCodeString", @"requestHeadersFlat", @"responseHeadersFlat", @"requestHTTPMethod"];
}

- (BOOL)canCopy
{
	return self.managedOutlineView.numberOfSelectedRows > 0;
}

- (void)copy:(id)sender
{
	NSMutableString* stringToCopy = [NSMutableString new];
	
	[self.managedOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		DTXNetworkSample* networkSample = [self.managedOutlineView itemAtRow:idx];
		
		[stringToCopy appendFormat:@"%@\n\n", networkSample.url];
	}];

	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:[stringToCopy stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forType:NSPasteboardTypeString];
}

@end
