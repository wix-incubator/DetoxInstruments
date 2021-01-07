//
//  DTXPlotRange.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/5/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPlotRange.h"

@interface DTXPlotRange ()

@property (nonatomic, readwrite) double position;
@property (nonatomic, readwrite) double length;

@end

@implementation DTXPlotRange

+ (instancetype)plotRangeWithPosition:(double)position length:(double)length
{
	DTXPlotRange* rv = [self new];
	rv.position = position;
	rv.length = length;
	
	return rv;
}

-(double)minLimit
{
	double doubleLoc = self.position;
	double doubleLen = self.length;
	
	if ( doubleLen < 0.0 ) {
		return doubleLoc + doubleLen;
	}
	else {
		return doubleLoc;
	}
}

- (id)_copyWithClass:(Class)cls zone:(NSZone*)zone
{
	DTXPlotRange* rv = [cls allocWithZone:zone];
	
	rv.position = self.position;
	rv.length = self.length;
	
	return rv;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [self _copyWithClass:DTXPlotRange.class zone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [self _copyWithClass:DTXMutablePlotRange.class zone:zone];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (%@, %@)", super.description, @(self.position), @(self.length)];
}

@end

@implementation DTXMutablePlotRange

@dynamic position;
@dynamic length;

@end

#if __has_include(<CorePlot/CPTMutablePlotRange.h>)
@implementation DTXPlotRange (CPTPlotRangeSupport)

+ (instancetype)plotRangeWithCPTPlotRange:(CPTPlotRange*)cptPlotRange
{
	return [self plotRangeWithPosition:cptPlotRange.locationDouble length:cptPlotRange.lengthDouble];
}

- (CPTMutablePlotRange*)cptPlotRange
{
	return [CPTMutablePlotRange plotRangeWithLocation:@(self.position) length:@(self.length)];
}

@end
#endif
