//
//  DTXStackedPlotGroup.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 05/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXStackedPlotGroup.h"

@implementation DTXStackedPlotGroup

-(void)layoutSublayers
{
	CGRect selfBounds = self.bounds;
	
	CPTSublayerArray *mySublayers = self.sublayers;
	
	if ( mySublayers.count > 0 ) {
		CGFloat leftPadding, topPadding, rightPadding, bottomPadding;
		
		[self sublayerMarginLeft:&leftPadding top:&topPadding right:&rightPadding bottom:&bottomPadding];
		
		CGSize subLayerSize = selfBounds.size;
		subLayerSize.width  -= leftPadding + rightPadding;
		subLayerSize.width   = MAX( subLayerSize.width, CPTFloat(0.0) );
		subLayerSize.width   = round(subLayerSize.width);
		subLayerSize.height -= topPadding + bottomPadding;
		subLayerSize.height  = MAX( subLayerSize.height, CPTFloat(0.0) );
		subLayerSize.height  = round(subLayerSize.height);
		
		CGRect subLayerFrame;
		subLayerFrame.origin = CGPointMake( round(leftPadding), round(bottomPadding) );
		subLayerFrame.size   = subLayerSize;
		
		NSUInteger count = mySublayers.count;
		
		[mySublayers enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			idx = count - 1 - idx;
			CGRect frameForCurrentSublayer = CGRectMake(subLayerFrame.origin.x, subLayerFrame.origin.y + (CGFloat)idx * (subLayerFrame.size.height / count + 1), subLayerFrame.size.width, subLayerFrame.size.height / count);
			obj.frame = frameForCurrentSublayer;
		}];
	}
}

-(void)layoutAndRenderInContext:(nonnull CGContextRef)context
{
	[super layoutAndRenderInContext:context];
}

@end
