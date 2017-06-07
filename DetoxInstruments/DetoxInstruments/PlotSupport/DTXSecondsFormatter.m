//
//  DTXSecondsFormatter.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSecondsFormatter.h"

@implementation DTXSecondsFormatter
{
	NSDateComponentsFormatter* _secondsFormatter;
	NSNumberFormatter* _numberFormatter;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
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
	}
	
	return self;
}

- (NSString *)stringForObjectValue:(id)obj
{
	NSTimeInterval ti = [obj doubleValue];
	return [NSString stringWithFormat:@"%@%@", [_secondsFormatter stringFromTimeInterval:ti], [_numberFormatter stringFromNumber:@(ti - (long)ti)]];
}

@end
