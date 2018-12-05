//
//  NSFormatter+PlotFormatters.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSFormatter+PlotFormatters.h"

@interface DTXDurationFormatter : NSDateComponentsFormatter

@property (nonatomic, assign) BOOL highPrecision;

@end
@implementation DTXDurationFormatter
{
	NSNumberFormatter* _numberFormatter;
}

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		_numberFormatter = [NSNumberFormatter new];
//		_numberFormatter.minimumIntegerDigits = 0;
//		_numberFormatter.maximumIntegerDigits = 0;
		_numberFormatter.maximumFractionDigits = 2;
//		_numberFormatter.decimalSeparator = @"";
	}
	
	return self;
}

- (NSString*)_usStringFromTimeInterval:(NSTimeInterval)ti
{
	return [NSString stringWithFormat:@"%@μs", [_numberFormatter stringFromNumber:@(ti * 1000000)]];
}

- (NSString*)_msStringFromTimeInterval:(NSTimeInterval)ti
{
	return [NSString stringWithFormat:@"%@ms", [_numberFormatter stringFromNumber:@(ti * 1000)]];
}

- (NSString*)stringFromTimeInterval:(NSTimeInterval)ti
{
	if(ti < 0.001)
	{
		return [self _usStringFromTimeInterval:ti];
	}
		
	if(ti < 1.0)
	{
		return [self _msStringFromTimeInterval:ti];
	}
	
	NSString* rv = [super stringFromTimeInterval:ti];
	
	if(_highPrecision == NO)
	{
		return rv;
	}
	
	NSTimeInterval ms = ti - floor(ti);
	if(ms == 0)
	{
		return rv;
	}
	
	return [NSString stringWithFormat:@"%@ %@", rv, [self _msStringFromTimeInterval:ms]];
}

- (NSString*)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	return [self stringFromTimeInterval:endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate];
}

@end

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
		_numberFormatter.minimumFractionDigits = 5;
		_numberFormatter.maximumFractionDigits = 5;
		
		self.maxMinutesZeroPadding = 2;
	}
	
	return self;
}

- (NSString *)stringForObjectValue:(id)obj
{
	NSTimeInterval ti = [obj doubleValue];
	
	NSString* minutes = [_minuteFormatter stringFromTimeInterval:ti];
	NSInteger actualPaddingNeeded = self.maxMinutesZeroPadding - (NSInteger)minutes.length;
	
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

+ (NSByteCountFormatter*)dtx_memoryFormatter
{
	static NSByteCountFormatter* byteCountFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		byteCountFormatter = [NSByteCountFormatter new];
		byteCountFormatter.countStyle = NSByteCountFormatterCountStyleMemory;
		byteCountFormatter.allowsNonnumericFormatting = NO;
	});
	
	return byteCountFormatter;
}

+ (NSNumberFormatter*)dtx_percentFormatter
{
	static NSNumberFormatter* numberFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		numberFormatter = [NSNumberFormatter new];
		numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
		numberFormatter.maximumFractionDigits = 3;
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

+ (NSDateComponentsFormatter *)dtx_durationFormatter
{
	static NSDateComponentsFormatter* durationFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		durationFormatter = [DTXDurationFormatter new];
		durationFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
		durationFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
	});
	
	return durationFormatter;
}

+ (NSDateComponentsFormatter *)dtx_highPrecisionDurationFormatter
{
	static DTXDurationFormatter* durationFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		durationFormatter = [DTXDurationFormatter new];
		durationFormatter.highPrecision = YES;
		durationFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
		durationFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
		durationFormatter.allowsFractionalUnits = YES;
	});
	
	return durationFormatter;
}


@end
