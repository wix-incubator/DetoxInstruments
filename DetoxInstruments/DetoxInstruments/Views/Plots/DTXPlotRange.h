//
//  DTXPlotRange.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/5/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<CorePlot/CPTMutablePlotRange.h>)
#import <CorePlot/CPTMutablePlotRange.h>
#endif

@interface DTXPlotRange : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, readonly) double position;
@property (nonatomic, readonly) double length;

+ (instancetype)plotRangeWithPosition:(double)position length:(double)length;
@property (nonatomic, readonly) double minLimit;

@end

@interface DTXMutablePlotRange : DTXPlotRange

@property (nonatomic) double position;
@property (nonatomic) double length;

@end

#if __has_include(<CorePlot/CPTMutablePlotRange.h>)
@interface DTXPlotRange (CPTPlotRangeSupport)

+ (instancetype)plotRangeWithCPTPlotRange:(CPTPlotRange*)cptPlotRange;
- (CPTMutablePlotRange*)cptPlotRange;

@end
#endif
