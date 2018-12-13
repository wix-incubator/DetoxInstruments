//
//  DTXSample+Additions.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+Additions.h"
#import "DTXInstruments+CoreDataModel.h"
#import "DTXInstrumentsModel.h"

static NSDictionary<NSString*, NSNumber*>* __classTypeMapping;
static NSDictionary<NSNumber*, Class>* __typeClassMapping;

@implementation DTXSample (Additions)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__classTypeMapping = @{NSStringFromClass([DTXPerformanceSample class]): @(DTXSampleTypePerformance),
							   NSStringFromClass([DTXAdvancedPerformanceSample class]): @(DTXSampleTypeAdvancedPerformance),
							   NSStringFromClass([DTXThreadPerformanceSample class]): @(DTXSampleTypeThreadPerformance),
							   NSStringFromClass([DTXNetworkSample class]): @(DTXSampleTypeNetwork),
							   NSStringFromClass([DTXTag class]): @(DTXSampleTypeTag),
							   NSStringFromClass([DTXLogSample class]): @(DTXSampleTypeLog),
                               NSStringFromClass([DTXReactNativePeroformanceSample class]): @(DTXSampleTypeReactNativePerformanceType),
							   NSStringFromClass([DTXSignpostSample class]): @(DTXSampleTypeSignpost),
							   NSStringFromClass([DTXReactNativeDataSample class]): @(DTXSampleTypeReactNativeBridgeDataType),
							   };
		__typeClassMapping = @{@(DTXSampleTypePerformance): ([DTXPerformanceSample class]),
							   @(DTXSampleTypeAdvancedPerformance): ([DTXAdvancedPerformanceSample class]),
							   @(DTXSampleTypeThreadPerformance): ([DTXThreadPerformanceSample class]),
							   @(DTXSampleTypeNetwork): ([DTXNetworkSample class]),
							   @(DTXSampleTypeTag): ([DTXTag class]),
							   @(DTXSampleTypeLog): ([DTXLogSample class]),
							   @(DTXSampleTypeReactNativePerformanceType): ([DTXReactNativePeroformanceSample class]),
							   @(DTXSampleTypeSignpost): ([DTXSignpostSample class]),
							   @(DTXSampleTypeReactNativeBridgeDataType): ([DTXReactNativeDataSample class]),
							   };
	});
}

+ (Class)classFromSampleType:(DTXSampleType)type
{
	return __typeClassMapping[@(type)];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
	self.sampleIdentifier = [NSUUID UUID].UUIDString;
	self.timestamp = [NSDate date];
	self.sampleType = [__classTypeMapping[NSStringFromClass(self.class)] unsignedIntegerValue];
}

@end
