//
//  NSFormatter+PlotFormatters.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "NSFormatter+PlotFormatters.h"
#import <tgmath.h>

@interface DTXDurationFormatter : NSFormatter

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
		_numberFormatter.maximumFractionDigits = 2;
	}
	
	return self;
}

- (NSString*)_usStringFromTimeInterval:(NSTimeInterval)ti
{
	return [NSString stringWithFormat:@"%@μs", [_numberFormatter stringFromNumber:@(ti * 1000000)]];
}

- (NSString*)_msStringFromTimeInterval:(NSTimeInterval)ti round:(BOOL)roundMs
{
	ti *= 1000;
	if(roundMs)
	{
		ti = round(ti);
	}
	
	return [NSString stringWithFormat:@"%@ms", [_numberFormatter stringFromNumber:@(ti)]];
}

- (NSString*)_hmsmsStringFromTimeInterval:(NSTimeInterval)ti
{
	NSMutableString* rv = [NSMutableString new];
	
	double hours = floor(ti / 3600);
	double minutes = floor(fmod(ti / 60, 60));
	double seconds = fmod(ti, 60);
	double secondsRound = floor(fmod(ti, 60));
	double ms = ti - floor(ti);
	
	if(hours > 0)
	{
		[rv appendFormat:@"%@h", [_numberFormatter stringFromNumber:@(hours)]];
	}
	
	if(minutes > 0)
	{
		if(rv.length != 0)
		{
			[rv appendString:@" "];
		}
		
		[rv appendFormat:@"%@m", [_numberFormatter stringFromNumber:@(minutes)]];
	}
	
	if(rv.length == 0)
	{
		if(seconds > 0)
		{
			if(rv.length != 0)
			{
				[rv appendString:@" "];
			}
			
			[rv appendFormat:@"%@s", [_numberFormatter stringFromNumber:@(seconds)]];
		}
	}
	else
	{
		if(secondsRound > 0)
		{
			[rv appendString:@" "];
			
			[rv appendFormat:@"%@s", [_numberFormatter stringFromNumber:@(secondsRound)]];
		}
		
		if(ms > 0)
		{
			[rv appendString:@" "];
			
			[rv appendString:[self _msStringFromTimeInterval:ms round:YES]];
		}
	}
	
	return rv;
}

- (NSString*)stringFromTimeInterval:(NSTimeInterval)ti
{
	if(ti < 0.001)
	{
		return [self _usStringFromTimeInterval:ti];
	}
		
	if(ti < 1.0)
	{
		return [self _msStringFromTimeInterval:ti round:NO];
	}
	
	return [self _hmsmsStringFromTimeInterval:ti];
}

- (NSString*)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
	return [self stringFromTimeInterval:endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate];
}

@end

@implementation DTXMainThreadUsageFormatter

- (NSString *)stringForObjectValue:(id)obj
{
	return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"MT", @"'Main Thread' abbreviation"), [NSFormatter.dtx_percentFormatter stringForObjectValue:obj]];
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
	static DTXDurationFormatter* durationFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		durationFormatter = [DTXDurationFormatter new];
	});
	
	return (id)durationFormatter;
}

+ (DTXMainThreadUsageFormatter*)dtx_mainThreadFormatter;
{
	static DTXMainThreadUsageFormatter* mainThreadFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mainThreadFormatter = [DTXMainThreadUsageFormatter new];
	});
	
	return mainThreadFormatter;
}

+ (NSNumberFormatter*)dtx_readibleCountFormatter
{
	static NSNumberFormatter* numberFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		numberFormatter = [NSNumberFormatter new];
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	});
	return numberFormatter;
}

@end
