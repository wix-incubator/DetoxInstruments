//
//  DTXCPTRangePlot.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 13/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXCPTRangePlot.h"

struct CGPointError {
	CGFloat x;
	CGFloat y;
	CGFloat high;
	CGFloat low;
	CGFloat left;
	CGFloat right;
};
typedef struct CGPointError CGPointError;

@interface CPTRangePlot ()

-(void)calculateViewPoints:(nonnull CGPointError *)viewPoints withDrawPointFlags:(nonnull BOOL *)drawPointFlags numberOfPoints:(NSUInteger)dataCount;
-(NSInteger)extremeDrawnPointIndexForFlags:(nonnull BOOL *)pointDrawFlags numberOfPoints:(NSUInteger)dataCount extremeNumIsLowerBound:(BOOL)isLowerBound;

@end

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

-(NSUInteger)dataIndexFromInteractionPoint:(CGPoint)point
{
	NSUInteger dataCount     = self.cachedDataCount;
	CGPointError *viewPoints = calloc(dataCount, sizeof(CGPointError) );
	BOOL *drawPointFlags     = calloc(dataCount, sizeof(BOOL) );
	
	[self calculatePointsToDraw:drawPointFlags numberOfPoints:dataCount forPlotSpace:(id)self.plotSpace includeVisiblePointsOnly:YES];
	[self calculateViewPoints:viewPoints withDrawPointFlags:drawPointFlags numberOfPoints:dataCount];
	
	NSInteger first = [self extremeDrawnPointIndexForFlags:drawPointFlags numberOfPoints:dataCount extremeNumIsLowerBound:YES];
	NSInteger result = NSNotFound;
	if ( first != NSNotFound )
	{
		CGPointError lastViewPoint;
		for ( NSUInteger i = (NSUInteger)first; i < dataCount; ++i ) {
			lastViewPoint = viewPoints[i];
			
			if (point.x >  lastViewPoint.left - 3.5 && point.x < lastViewPoint.right + 3.5 && point.y > lastViewPoint.low - 3.5 && point.y < lastViewPoint.high + 3.5) {
				result = i;
				break;
			}
		}
	}
	
	free(viewPoints);
	free(drawPointFlags);
	
	return (NSUInteger)result;
}


@end
