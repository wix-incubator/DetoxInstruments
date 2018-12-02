//
//  DTXKeyedDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXKeyedDataExporter.h"
#import "NSFormatter+PlotFormatters.h"

@implementation DTXKeyedDataExporter

- (NSArray<NSString *> *)exportedKeyPaths
{
	return nil;
}

- (NSArray<NSString *> *)titles
{
	return nil;
}

- (id (^)(id))transformer
{
	return nil;
}

- (NSString*)_descriptionForObject:(id)object keyPath:(NSString*)keyPath
{
	if([object isKindOfClass:NSDate.class])
	{
		return [NSDateFormatter localizedStringFromDate:object dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterLongStyle];
	}
	
	return [object description];
}

- (NSData*)_dataForCSVWithError:(NSError**)error
{
	NSArray<DTXSample*>* samples = [self.document.firstRecording.managedObjectContext executeFetchRequest:self.fetchRequest error:error];
	if(samples == nil)
	{
		return nil;
	}
	
	NSMutableData* rv = [NSMutableData new];
	
	NSArray* titles = self.titles;
	[titles enumerateObjectsUsingBlock:^(NSString* _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv appendData:[title dataUsingEncoding:NSUTF8StringEncoding]];
		if(idx < titles.count - 1)
		{
			[rv appendData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}];
	
	[rv appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	[samples enumerateObjectsUsingBlock:^(id _Nonnull sample, NSUInteger idx, BOOL * _Nonnull stop) {
		id (^transformer)(id) = self.transformer;
		if(transformer)
		{
			sample = transformer(sample);
		}
		
		NSArray* keys = self.exportedKeyPaths;
		[keys enumerateObjectsUsingBlock:^(NSString* _Nonnull keyPath, NSUInteger idx, BOOL * _Nonnull stop) {
			NSObject* value = [sample valueForKeyPath:keyPath];
			[rv appendData:[[NSString stringWithFormat:@"\"%@\"", [self _descriptionForObject:value keyPath:keyPath]] dataUsingEncoding:NSUTF8StringEncoding]];
			if(idx < keys.count - 1)
			{
				[rv appendData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}];
		
		if(idx < samples.count - 1)
		{
			[rv appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}];
	
	return rv;
}

- (NSData*)exportDataWithType:(DTXDataExportType)exportType error:(NSError**)error
{
	if(self.exportedKeyPaths == nil || self.titles == nil || self.fetchRequest == nil || self.exportedKeyPaths.count != self.titles.count)
	{
		if(error != NULL)
		{
			[NSException raise:NSInternalInconsistencyException format:@"Invalid params for DTXKeyedDataExporter."];
			return nil;
		}
	}
	
	switch (exportType)
	{
		case DTXDataExportTypeCSV:
			return [self _dataForCSVWithError:error];
		default:
			return [super exportDataWithType:exportType error:error];
	}
}

- (NSFetchRequest*)fetchRequest
{
	return nil;
}

@end
