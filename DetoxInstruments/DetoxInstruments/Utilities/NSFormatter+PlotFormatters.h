//
//  NSFormatter+PlotFormatters.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTXSecondsFormatter : NSFormatter

@property (nonatomic) NSUInteger maxMinutesZeroPadding;

@end


@interface NSFormatter (PlotFormatters)

+ (NSFormatter*)dtx_stringFormatter;
+ (NSFormatter*)dtx_memoryFormatter;
+ (NSFormatter*)dtx_percentFormatter;
+ (DTXSecondsFormatter*)dtx_secondsFormatter;

@end
