//
//  DTXRNAsyncStorageInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/26/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNAsyncStorageInspectorDataProvider.h"

@implementation DTXRNAsyncStorageInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	NSMutableArray* contentArray = [NSMutableArray new];
	
	DTXReactNativeAsyncStorageSample* dataSample = self.sample;
	
	DTXInspectorContent* general = [DTXInspectorContent new];
	general.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = dataSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Operation", @"") description:dataSample.operation]];
	
	if(dataSample.fetchCount > 0)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Fetch Duration", @"") description:[NSFormatter.dtx_durationFormatter stringFromTimeInterval:dataSample.fetchDuration]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Fetch Count", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(dataSample.fetchCount)]]];
	}
	else
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Save Duration", @"") description:[NSFormatter.dtx_durationFormatter stringFromTimeInterval:dataSample.saveDuration]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Save Count", @"") description:[NSFormatter.dtx_stringFormatter stringForObjectValue:@(dataSample.saveCount)]]];
	}
	
	general.content = content;
	
	[contentArray addObject:general];
	
	DTXReactNativeAsyncStorageData* data = dataSample.data;
	
	if(data && data.data != nil)
	{
		DTXInspectorContent* dataContent = [DTXInspectorContent new];
		dataContent.title = NSLocalizedString(@"Data", @"");
		
		NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
		if(data.isKeysOnly == NO)
		{
			[data.data enumerateObjectsUsingBlock:^(NSArray<NSString*>* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[content addObject:[DTXInspectorContentRow contentRowWithTitle:obj.firstObject description:obj.lastObject]];
			}];
		}
		else
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Keys", @"") description:[data.data componentsJoinedByString:@", "]]];
		}
		
		dataContent.content = content;
		
		[contentArray addObject:dataContent];
	}
	
	if(data && data.error != nil)
	{
		DTXInspectorContent* dataContent = [DTXInspectorContent new];
		dataContent.title = NSLocalizedString(@"Error", @"");
		dataContent.content = @[[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Error", @"") description:data.error[@"message"]]];
		[contentArray addObject:dataContent];
	}
	
//	if(dataSample.data.arguments.count > 0)
//	{
//		DTXInspectorContent* arguments = [DTXInspectorContent new];
//		arguments.title = NSLocalizedString(@"Arguments", @"");
//
//		NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
//
//		[dataSample.data.arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//			[content addObject:[DTXInspectorContentRow contentRowWithTitle:[NSString stringWithFormat:@"%lu", idx] description:obj]];
//		}];
//
//		arguments.content = content;
//
//		[contentArray addObject:arguments];
//	}
//
//	if(dataSample.data.returnValue.length > 0 && [dataSample.data.returnValue isEqualToString:@"null"] == NO)
//	{
//		DTXInspectorContent* arguments = [DTXInspectorContent new];
//		arguments.title = NSLocalizedString(@"Return Value", @"");
//
//		NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
//
//		[content addObject:[DTXInspectorContentRow contentRowWithTitle:@"Return Value" description:dataSample.data.returnValue]];
//
//		arguments.content = content;
//
//		[contentArray addObject:arguments];
//	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

@end
