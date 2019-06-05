//
//  DTXPlotRange.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/5/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot/CPTMutablePlotRange.h>

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

@interface DTXPlotRange (CPTPlotRangeSupport)

+ (instancetype)plotRangeWithCPTPlotRange:(CPTPlotRange*)cptPlotRange;
- (CPTMutablePlotRange*)cptPlotRange;

@end
