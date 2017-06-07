//
//  NSFormatter+PlotFormatters.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSFormatter+PlotFormatters.h"

@interface _DTXToStringFormatter : NSFormatter @end

@implementation _DTXToStringFormatter

- (nullable NSString *)stringForObjectValue:(nullable id)obj
{
	if([obj respondsToSelector:@selector(stringValue)])
	{
		return [obj stringValue];
	}
	
	return [obj description];
}

@end

@implementation NSFormatter (PlotFormatters)

+ (NSFormatter*)dtx_stringFormatter
{
	static _DTXToStringFormatter* passthroughFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		passthroughFormatter = [_DTXToStringFormatter new];
	});
	
	return passthroughFormatter;
}

+ (NSFormatter*)dtx_memoryFormatter
{
	static NSByteCountFormatter* byteCountFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		byteCountFormatter = [NSByteCountFormatter new];
		byteCountFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
	});
	
	return byteCountFormatter;
}

+ (NSFormatter*)dtx_percentFormatter
{
	static NSNumberFormatter* numberFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		numberFormatter = [NSNumberFormatter new];
		numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
	});
	
	return numberFormatter;
}

@end
