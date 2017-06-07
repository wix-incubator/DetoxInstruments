//
//  DTXAxisHeaderPlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXDocument.h"
#import "DTXPlotController.h"

@interface DTXAxisHeaderPlotController : NSObject <DTXPlotController>

- (instancetype)initWithDocument:(DTXDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
