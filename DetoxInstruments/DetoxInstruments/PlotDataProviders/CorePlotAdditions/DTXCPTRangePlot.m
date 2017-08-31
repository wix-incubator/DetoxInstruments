//
//  DTXCPTRangePlot.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 13/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPTRangePlot.h"

@implementation DTXCPTRangePlot

//- (BOOL)_canDisplayConcurrently
//{
//	return YES;
//}

-(void)calculatePointsToDraw:(nonnull BOOL *)pointDrawFlags numberOfPoints:(NSUInteger)dataCount forPlotSpace:(nonnull CPTXYPlotSpace *)xyPlotSpace includeVisiblePointsOnly:(BOOL)visibleOnly
{
	for(NSUInteger i = 0; i < dataCount; i++)
	{
		pointDrawFlags[i] = YES;
	}
}

@end
