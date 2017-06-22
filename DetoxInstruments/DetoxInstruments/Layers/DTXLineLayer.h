//
//  DTXLineLayer.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <CorePlot/CorePlot.h>

@interface DTXLineLayer : CPTLayer

@property (nonatomic) CGFloat dataPoint;
@property (nonatomic) CGColorRef lineColor;
@property (nonatomic) CGColorRef pointColor;

@end
