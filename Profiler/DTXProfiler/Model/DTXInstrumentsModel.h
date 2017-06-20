//
//  DTXInstrumentsModel.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "NSManagedObject+Additions.h"
#import "DTXSample+Additions.h"
#import "DTXRecording+Additions.h"
#import "DTXPerformanceSample+CoreDataClass.h"
#import "DTXAdvancedPerformanceSample+CoreDataClass.h"
#import "DTXNetworkSample+CoreDataClass.h"
#import "DTXNetworkData+CoreDataClass.h"
#import "DTXLogSample+CoreDataClass.h"
#import "DTXThreadInfo+CoreDataClass.h"
#import "DTXThreadPerformanceSample+CoreDataClass.h"

typedef NS_ENUM(NSUInteger, DTXSampleType) {
	DTXSampleTypeUnknown				= 0,
	
	DTXSampleTypePerformance			= 10,
	DTXSampleTypeAdvancedPerformance	= 11,
	DTXSampleTypeThreadPerformance		= 12,
	
	DTXSampleTypeNetwork				= 50,
	
	DTXSampleTypeLog					= 100,
	
	DTXSampleTypeTag					= 200,
	
	DTXSampleTypeGroup					= 1000,
	
	DTXSampleTypeUser					= 20000,
};
