//
//  DTXPlotView-Private.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/3/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXPlotView.h"

@interface _DTXDrawingZone : NSObject

@property (nonatomic) double start;
@property (nonatomic) NSUInteger drawingType;

@property (nonatomic, weak) _DTXDrawingZone* nextZone;

@end

static DTX_ALWAYS_INLINE double lerp(double a, double b, double t)
{
	return a + (b - a) * t;
}

static DTX_ALWAYS_INLINE void __DTXFillZones(DTXPlotView* self, NSMutableArray<_DTXDrawingZone*>* zones)
{
	CGFloat graphViewRatio = self.bounds.size.width / self.plotRange.length;
	CGFloat offset = - graphViewRatio * self.plotRange.position;
	
	_DTXDrawingZone* zone = [_DTXDrawingZone new];
	zone.start = offset + graphViewRatio * 0;
	[zones addObject:zone];
	
	if(self.fadesOnRangeAnnotation == NO)
	{
		return;
	}
	
	for(DTXPlotViewRangeAnnotation* annotation in self.annotations)
	{
		if([annotation isKindOfClass:DTXPlotViewRangeAnnotation.class] == NO)
		{
			continue;
		}
		
		double start = offset + graphViewRatio * annotation.position;
		double end = offset + graphViewRatio * annotation.end;
		
		_DTXDrawingZone* zone;
		if(zones.lastObject.start == start)
		{
			zone = zones.lastObject;
		}
		else
		{
			zone = [_DTXDrawingZone new];
			zone.start = start;
			zones.lastObject.nextZone = zone;
			[zones addObject:zone];
		}
		zone.drawingType = 1;
		
		_DTXDrawingZone* next = [_DTXDrawingZone new];
		zone.nextZone = next;
		next.start = end;
		[zones addObject:next];
	}
}

static DTX_ALWAYS_INLINE double __DTXBottomInset(NSEdgeInsets insets, BOOL isFlipped)
{
	return isFlipped == NO ? insets.bottom : insets.top;
}

@interface DTXPlotView ()

- (void)_commonInit;
- (BOOL)_hasRangeAnnotations;
- (void)_clicked:(NSClickGestureRecognizer*)cgr;

@end
