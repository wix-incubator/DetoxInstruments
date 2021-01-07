//
//  DTXRNBridgeDataDataDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 10/29/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRNBridgeDataDataDataProvider.h"
#import "DTXRNBridgeDataDataInspectorDataProvider.h"

@implementation DTXRNBridgeDataDataDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXRNBridgeDataDataInspectorDataProvider class];
}

- (NSString *)identifier
{
	return @"BridgeData";
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Bridge Data", @"");
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"bridge_data"];
	image.size = NSMakeSize(16, 16);
	
	return image;
}

- (Class)sampleClass
{
	return DTXReactNativeDataSample.class;
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* type = [DTXColumnInformation new];
	type.title = NSLocalizedString(@"Type", @"");
	type.minWidth = 45;
	type.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isFromNative" ascending:YES];
	
	DTXColumnInformation* function = [DTXColumnInformation new];
	function.title = NSLocalizedString(@"Function", @"");
	function.minWidth = 200;
	function.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"function" ascending:YES];
	
	DTXColumnInformation* arguments = [DTXColumnInformation new];
	arguments.title = NSLocalizedString(@"Data", @"");
	arguments.automaticallyGrowsWithTable = YES;
	
	return @[type, function, arguments];
}

- (NSString*)_dataFromSample:(DTXReactNativeDataSample*)sample
{
	NSMutableString* str = [NSMutableString new];
	
	if(sample.data.arguments.count > 0)
	{
		[str appendFormat:@"%@: ", NSLocalizedString(@"Arguments", @"")];
		[str appendString:[sample.data.arguments componentsJoinedByString:@", "]];
	}
	
	if(sample.data.returnValue != nil)
	{
		if(str.length != 0)
		{
			[str appendString:@" "];
		}
		
		[str appendFormat:@"%@: ", NSLocalizedString(@"Return Value", @"")];
		[str appendString:sample.data.returnValue];
	}
	
	return str;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	DTXReactNativeDataSample* sample = (DTXReactNativeDataSample*)item;
	
	switch(column)
	{
		case 0:
			return sample.isFromNative ? @"N → JS" : @"JS → N";
		case 1:
			return sample.function;
		case 2:
			return [self _dataFromSample:sample];
		default:
			return @"";
	}
}

@end
