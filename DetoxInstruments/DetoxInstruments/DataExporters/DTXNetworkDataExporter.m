//
//  DTXNetworkDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/2/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXNetworkDataExporter.h"

@implementation DTXNetworkDataExporter

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO && sampleType in %@", @[@(DTXSampleTypeNetwork)]];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

- (NSArray<NSString *> *)exportedKeyPaths
{
	return @[@"timestamp", @"requestDataLength", @"requestHTTPMethod", @"responseTimestamp", @"responseDataLength", @"responseStatusCode", @"totalDataLength", @"url"];
}

- (NSArray<NSString *> *)titles
{
	return @[@"Request Time", @"Request Data Length", @"Request HTTP Method", @"Response Time", @"Response Data Length", @"Response Status Code", @"Total Data Length", @"URL"];
}

@end
