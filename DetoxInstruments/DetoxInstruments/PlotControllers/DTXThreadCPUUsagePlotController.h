//
//  DTXThreadCPUUsagePlotController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXCPUUsagePlotController.h"

@interface DTXThreadCPUUsagePlotController : DTXCPUUsagePlotController

- (instancetype)initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar NS_UNAVAILABLE;
- (instancetype)initWithDocument:(DTXRecordingDocument*)document threadInfo:(DTXThreadInfo*)threadInfo isForTouchBar:(BOOL)isForTouchBar;

@end
	
