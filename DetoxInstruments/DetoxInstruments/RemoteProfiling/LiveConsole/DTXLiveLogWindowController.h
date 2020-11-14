//
//  DTXLiveLogWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/28/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRemoteTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface DTXLiveLogWindowController : NSWindowController

@property (nonatomic, strong) DTXRemoteTarget* profilingTarget;

@end

NS_ASSUME_NONNULL_END
