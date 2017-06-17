//
//  DTXSampleGroupProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXInstrumentsModel.h"
#import "DTXInspectorDataProvider.h"

@interface DTXSampleGroupProxy : NSObject

@property (nonatomic, strong) NSArray<DTXSample*>* samples;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSDate* closeTimestamp;
@property (nonatomic, strong) NSString* name;

@end

@interface DTXGroupInspectorDataProvider : DTXInspectorDataProvider @end
