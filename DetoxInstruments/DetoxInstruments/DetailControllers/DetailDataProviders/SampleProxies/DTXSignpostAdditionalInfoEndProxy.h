//
//  DTXSignpostAdditionalInfoEndProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/5/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTXSignpostSample;

@interface DTXSignpostAdditionalInfoEndProxy : NSObject

- (instancetype)initWithSignpostSample:(DTXSignpostSample*)sample;

@property (nonatomic, strong, readonly) DTXSignpostSample* sample;
@property (nonatomic, copy, readonly) NSString *additionalInfoEnd;

@end
