//
//  DTXKeyedDataExporter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/29/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXKeyedDataExporter.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXRecording+UIExtensions.h"

static NSCharacterSet* _disallowedinCSV;

@implementation DTXKeyedDataExporter

+(void)load
{
	_disallowedinCSV = [NSCharacterSet characterSetWithCharactersInString:@"\r\n,\""];
}

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

- (NSString*)_descriptionForObject:(id)object keyPath:(NSString*)keyPath exportType:(DTXDataExportType)exportType
{
	if(object == nil)
	{
		return @"";
	}
	
	if([object isKindOfClass:NSString.class])
	{
		if(exportType == DTXDataExportTypeCSV && [object rangeOfCharacterFromSet:_disallowedinCSV].location != NSNotFound)
		{
			return @"<>";
		}
		
		return object;
	}
	
	if([object isKindOfClass:NSDate.class])
	{
		if([keyPath isEqualToString:@"timestamp"] || [keyPath isEqualToString:@"endTimestamp"] || [keyPath isEqualToString:@"responseTimestamp"])
		{
			NSTimeInterval ti = [object timeIntervalSinceDate:self.document.firstRecording.defactoStartTimestamp];
			return [NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)];
		}
		
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
			[rv appendData:[[NSString stringWithFormat:@"\"%@\"", [self _descriptionForObject:value keyPath:keyPath exportType:DTXDataExportTypeCSV]] dataUsingEncoding:NSUTF8StringEncoding]];
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
