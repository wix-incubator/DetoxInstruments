//
//  DTXSample+Additions.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+CoreDataClass.h"
#import "DTXRecording+Additions.h"

@import Foundation;

typedef NS_ENUM(NSUInteger, DTXSampleType) {
	DTXSampleTypeUnknown				        = 0,
	
	DTXSampleTypePerformance			        = 10,
	DTXSampleTypeAdvancedPerformance	        = 11,
	DTXSampleTypeThreadPerformance		        = 12,
	
	DTXSampleTypeNetwork				        = 50,
	
	DTXSampleTypeSignpost				        = 70,
	
	DTXSampleTypeLog					        = 100,
	
	DTXSampleTypeTag					        = 200,
	DTXSampleTypeGroup					        = 1000,
	
	DTXSampleTypeReactNativePerformanceType     = 10000,
	DTXSampleTypeReactNativeBridgeDataType      = 10001,
	
	DTXSampleTypeUser					        = 20000,
};

@interface DTXSample (Additions)

+ (Class)classFromSampleType:(DTXSampleType)type;

@end
