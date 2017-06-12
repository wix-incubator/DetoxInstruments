//
//  NSFormatter+PlotFormatters.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSFormatter+PlotFormatters.h"

@implementation DTXSecondsFormatter
{
	NSDateComponentsFormatter* _secondsFormatter;
	NSDateComponentsFormatter* _minuteFormatter;
	NSNumberFormatter* _numberFormatter;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_minuteFormatter = [NSDateComponentsFormatter new];
		_minuteFormatter.allowedUnits = NSCalendarUnitMinute;
		_minuteFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
		_minuteFormatter.allowsFractionalUnits = NO;
		
		_secondsFormatter = [NSDateComponentsFormatter new];
		_secondsFormatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
		_secondsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
		_secondsFormatter.allowsFractionalUnits = YES;
		
		_numberFormatter = [NSNumberFormatter new];
		_numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		_numberFormatter.minimumIntegerDigits = 0;
		_numberFormatter.maximumIntegerDigits = 0;
		_numberFormatter.minimumFractionDigits = 3;
		_numberFormatter.maximumFractionDigits = 3;
		
		self.maxMinutesZeroPadding = 2;
	}
	
	return self;
}

- (NSString *)stringForObjectValue:(id)obj
{
	NSTimeInterval ti = [obj doubleValue];
	
	NSString* minutes = [_minuteFormatter stringFromTimeInterval:ti];
	NSUInteger actualPaddingNeeded = self.maxMinutesZeroPadding - minutes.length;
	
	NSString* formattedString = [NSString stringWithFormat:@"%@%@", [_secondsFormatter stringFromTimeInterval:ti], [_numberFormatter stringFromNumber:@(ti - (long)ti)]];
	
	if(actualPaddingNeeded <= 0)
	{
		return formattedString;
	}
	
	return [[@"" stringByPaddingToLength:actualPaddingNeeded withString:@"0" startingAtIndex:0] stringByAppendingString:formattedString];
}

@end

@interface _DTXToStringFormatter : NSFormatter @end

@implementation _DTXToStringFormatter

- (nullable NSString *)stringForObjectValue:(nullable id)obj
{
	if([obj isKindOfClass:[NSString class]])
	{
		return obj;
	}
	
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

+ (NSFormatter *)dtx_secondsFormatter
{
	static DTXSecondsFormatter* secondsFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		secondsFormatter = [DTXSecondsFormatter new];
	});
	
	return secondsFormatter;
}

@end
