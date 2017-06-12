//
//  DTXBottomContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"
#import "DTXUIDataProvider.h"

@interface DTXBottomContentController : NSViewController

@property (nonatomic, strong) DTXUIDataProvider* managingDataProvider;

@end
