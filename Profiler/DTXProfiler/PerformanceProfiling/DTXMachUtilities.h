//
//  DTXMachUtilities.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 04/09/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <mach/mach.h>

int DTXCallStackSymbolsForMachThread(thread_act_t thread, void** buffer, int size);
