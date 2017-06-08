//
//  DTXNetworkRequestsPlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkRequestsPlotController.h"
#import "DTXNetworkSample+CoreDataClass.h"
#import "NSFormatter+PlotFormatters.h"

@implementation DTXNetworkRequestsPlotController

- (NSArray<NSArray<NSDictionary<NSString*, id>*>*>*)samplesForPlots
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.resultType = NSDictionaryResultType;
		fr.propertiesToFetch = @[@"timestamp", sampleKey];
		
		NSArray* results = [self.document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
		
		if(results == nil)
		{
			*stop = YES;
			return;
		}
		
		[rv addObject:results];
	}];
	
	if(rv.count != self.sampleKeys.count)
	{
		return nil;
	}
	
	return rv;
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Network Requests", @"");
}

- (NSImage*)displayIcon
{
	return [NSImage imageNamed:@"networkActivity"];
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[@"totalDataLength"];
}

- (NSArray<NSString *> *)plotTitles
{
	return @[NSLocalizedString(@"URL", @"")];
}

- (NSArray<NSColor*>*)plotColors
{
	return @[[NSColor colorWithRed:198.0/255.0 green:109.0/255.0 blue:218.0/255.0 alpha:1.0]];
}

- (BOOL)isStepped
{
	return YES;
}

- (NSFormatter*)formatterForDataPresentation
{
	return [NSFormatter dtx_memoryFormatter];
}

@end
