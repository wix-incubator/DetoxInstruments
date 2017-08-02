//
//  DTXColorTransformer.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXColorTransformer.h"
#import "DTXColor.h"

#define __DTX_MAX_NUMBER_OF_COMPONENTS 4

@interface __DTXColorRep : NSObject <NSSecureCoding>
{
	double _components[__DTX_MAX_NUMBER_OF_COMPONENTS];
}

@property (nonatomic, strong) NSData* colorspaceICCData;
@property (nonatomic, assign) NSUInteger numberOfComponents;
@property (nonatomic, assign) double* components;

@end

@implementation __DTXColorRep

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (double *)components
{
	return _components;
}

- (void)setComponents:(double *)components
{
	memcpy(_components, components, sizeof(double) * 4);
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
	
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
	return nil;
}

@end

//CGColorSpaceCreateWithICCData
//typedef struct {
//	uint8_t numberOfComponents;
//	double components[__DTX_MAX_NUMBER_OF_COMPONENTS];
//} __DTXColorTransformerColorRep;

@implementation DTXColorTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (nullable id)transformedValue:(nullable id)value
{
//	if([value isKindOfClass:DTXColor.class] == NO)
//	{
		return nil;
//	}
	
//	DTXColor* color = value;
	
//	__DTXColorTransformerColorRep colorRep;
//	const CGFloat* components = CGColorGetComponents(color.CGColor);
//	colorRep.numberOfComponents = CGColorGetNumberOfComponents(color.CGColor);
//	for(NSUInteger idx = 0; idx < colorRep.numberOfComponents; idx++)
//	{
//		colorRep.components[idx] = components[idx];
//	}
//
//	NSValue* val = [NSValue valueWithBytes:&colorRep objCType:@encode(__DTXColorTransformerColorRep)];
//
//	return [NSKeyedArchiver archivedDataWithRootObject:val];
}

- (nullable id)reverseTransformedValue:(nullable id)value
{
//	if([value isKindOfClass:NSData.class] == NO)
//	{
//		return nil;
//	}
//	
//	NSValue* val = [NSKeyedUnarchiver unarchiveObjectWithData:value];
//	__DTXColorTransformerColorRep colorRep;
//	[val getValue:&colorRep];
//	CGFloat components[__DTX_MAX_NUMBER_OF_COMPONENTS];
//	
//	for(NSUInteger idx = 0; idx < colorRep.numberOfComponents; idx++)
//	{
//		components[idx] = colorRep.components[idx];
//	}
//	
//	CGColorSpaceCreateWithPlatformColorSpace
	
//	CGColor
	
	return nil;
//	return [[DTXColor alloc] ];
}

@end
