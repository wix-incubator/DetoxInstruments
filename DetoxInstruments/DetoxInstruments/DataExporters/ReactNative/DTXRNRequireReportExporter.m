//
//  DTXRNRequireReportExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/10/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXRNRequireReportExporter.h"

@implementation DTXRNRequireReportExporter

+ (BOOL)supportsAsynchronousExport
{
	return YES;
}

static NSString* __cleanedUpString(NSString* str, BOOL leafOnly)
{
	NSString* rv = [str substringFromIndex:11];
	if(leafOnly)
	{
		rv = [rv lastPathComponent];
	}
	
	return rv;
}

- (NSData *)_htmlReportForRNJSRequiresWithError:(NSError**)error
{
	if(self.document.recordings.firstObject.hasReactNative == NO)
	{
		if(error != NULL)
		{
			*error = [NSError errorWithDomain:@"DTXErrorDomain" code:24 userInfo:@{NSLocalizedDescriptionKey: @"React Native not available in profiled app."}];
		}
		
		return nil;
	}
	
	__block NSArray<NSDictionary*>* samples = nil;
	__block dispatch_group_t wait = nil;
	__block NSError* inner = nil;
	
	void (^fetchBlock)(NSManagedObjectContext* ctx) = ^ (NSManagedObjectContext* ctx)
	{
		NSFetchRequest* fr = [DTXSignpostSample fetchRequest];
		fr.predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH %@", @"JS_require_"];
		fr.resultType = NSDictionaryResultType;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.propertiesToFetch = @[@"sampleIdentifier", @"timestamp", @"endTimestamp", @"name", @"duration"];
		
		samples = [ctx executeFetchRequest:fr error:&inner];
		
		if(wait != nil)
		{
			dispatch_group_leave(wait);
		}
	};
	
	if(error != NULL)
	{
		*error = inner;
	}
	
	if(inner != nil)
	{
		return nil;
	}
	
	if(NSThread.isMainThread)
	{
		fetchBlock(self.document.viewContext);
	}
	else
	{
		wait = dispatch_group_create();
		dispatch_group_enter(wait);
		[self.document performBackgroundTask:fetchBlock];
		dispatch_group_wait(wait, DISPATCH_TIME_FOREVER);
	}
	
	NSMutableArray<NSDictionary*>* objects = [NSMutableArray new];
	
	NSDate* startTime = self.document.firstRecording.startTimestamp;
	
	NSMutableArray<NSMutableDictionary*>* parentQueue = [NSMutableArray new];
	[samples enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([samples[idx][@"duration"] doubleValue] == 0)
		{
			return;
		}
		
		NSMutableDictionary* objToAdd = [@{@"name": __cleanedUpString(samples[idx][@"name"], YES), @"value": samples[idx][@"duration"], @"children": [NSMutableArray new], @"actualObj": obj} mutableCopy];
		
		while(parentQueue.count > 0 && [parentQueue.lastObject[@"actualObj"][@"endTimestamp"] compare:obj[@"timestamp"]] == NSOrderedAscending)
		{
			[parentQueue.lastObject removeObjectForKey:@"actualObj"];
			[parentQueue removeLastObject];
		}
		NSMutableArray* arrayToAddTo = parentQueue.lastObject ? parentQueue.lastObject[@"children"] : objects;
		if(parentQueue.lastObject)
		{
			parentQueue.lastObject[@"value"] = @([parentQueue.lastObject[@"value"] doubleValue] - [samples[idx][@"duration"] doubleValue]);
		}
		[arrayToAddTo addObject:objToAdd];
		[parentQueue addObject:objToAdd];
	}];
	
	if(parentQueue.lastObject)
	{
		[parentQueue.lastObject removeObjectForKey:@"actualObj"];
	}
	
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@{@"name": self.document.firstRecording.appName, @"children": objects} options:NSJSONWritingPrettyPrinted error:error];
	NSString* str = [NSString stringWithFormat:@"const data = %@;", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
	
	[str writeToFile:@"/Users/lnatan/Desktop/flare.js" atomically:YES encoding:NSUTF8StringEncoding error:error];
	
//	NSData* rv = nil;
//	NSMutableString* html = [[NSMutableString alloc] initWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"ReportHTMLJSRequire" withExtension:@"html"] usedEncoding:NULL error:NULL];
	
//	NSString* nodesAndEdges = [NSString stringWithFormat:@"var nodes = new vis.DataSet(%@);\nvar edges = new vis.DataSet(%@);\n",
//	 [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:nodes options:NSJSONWritingFragmentsAllowed error:NULL] encoding:NSUTF8StringEncoding],
//	 [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:edges options:NSJSONWritingFragmentsAllowed error:NULL] encoding:NSUTF8StringEncoding]];
	
//	[html replaceOccurrencesOfString:@"//*edges_nodes*//" withString:nodesAndEdges options:0 range:NSMakeRange(0, html.length)];
	
//	rv = [html dataUsingEncoding:NSUTF8StringEncoding];
	
//	[rv writeToFile:@"/Users/lnatan/Desktop/omgzzz.html" atomically:YES];
//	return rv;
	
	return nil;
}

- (NSData *)exportDataWithType:(DTXDataExportType)exportType error:(NSError *__autoreleasing *)error
{
//	switch (exportType)
//	{
//		case DTXDataExportTypeHTML:
			return [self _htmlReportForRNJSRequiresWithError:error];
//			break;
//		default:
//			return [super exportDataWithType:exportType error:error];
//	}
}

@end
