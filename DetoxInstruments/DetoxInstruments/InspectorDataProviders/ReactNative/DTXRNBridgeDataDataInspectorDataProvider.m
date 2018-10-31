//
//  DTXRNBridgeDataDataInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 10/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXRNBridgeDataDataInspectorDataProvider.h"

@implementation DTXRNBridgeDataDataInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	NSMutableArray* contentArray = [NSMutableArray new];
	
	DTXReactNativeDataSample* dataSample = self.sample;
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Info", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = dataSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Type", @"") description:dataSample.isFromNative ? @"N → JS" : @"JS → N"]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Function", @"") description:dataSample.function]];
	
	request.content = content;
	
	[contentArray addObject:request];
	
	if(dataSample.data.arguments.count > 0)
	{
		DTXInspectorContent* arguments = [DTXInspectorContent new];
		arguments.title = NSLocalizedString(@"Arguments", @"");
		
		NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];

		[dataSample.data.arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:[NSString stringWithFormat:@"%lu", idx] description:obj]];
		}];
		
		arguments.content = content;
		
		[contentArray addObject:arguments];
	}
	
	if(dataSample.data.returnValue.length > 0 && [dataSample.data.returnValue isEqualToString:@"null"] == NO)
	{
		DTXInspectorContent* arguments = [DTXInspectorContent new];
		arguments.title = NSLocalizedString(@"Return Value", @"");
		
		NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:@"Return Value" description:dataSample.data.returnValue]];
		
		arguments.content = content;
		
		[contentArray addObject:arguments];
	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

@end
