//
//  DTXSignpostSampleWithChildrenProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/7/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXSampleContainerProxy.h"

@interface DTXSignpostSampleWithChildrenProxy : NSObject <DTXSampleGroupProxy>

+ (NSArray<DTXSignpostSampleWithChildrenProxy*>*)sortedSamplesFromFetchedResultsController:(NSFetchedResultsController*)frc;

@property (nonatomic, strong, readonly) DTXSignpostSample* sample;
@property (nonatomic, strong, readonly) NSDate* timestamp;
@property (nonatomic, strong, readonly) NSDate* endTimestamp;

@end
