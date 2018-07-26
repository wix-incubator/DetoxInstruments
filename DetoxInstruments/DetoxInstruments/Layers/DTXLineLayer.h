//
//  DTXLineLayer.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <CorePlot/CorePlot.h>

@interface DTXLineLayer : CPTLayer

@property (nonatomic) NSArray<NSColor*>* lineColors;

@property (nonatomic) NSArray<NSNumber*>* dataPoints;
@property (nonatomic) NSArray<NSColor*>* pointColors;

@end
