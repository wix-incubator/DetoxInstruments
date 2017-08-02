//
//  DTXColorCommon.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 31/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#ifndef DTXColorCommon_h
#define DTXColorCommon_h

#if __has_include(<UIKit/UIKit.h>)
#define __DTXColorClass UIColor
#import <UIKit/UIKit.h>
#endif
//#if __has_include(<AppKit/AppKit>)
//#define __DTXColorClass NSColor
//#import <AppKit/AppKit.h>
//#endif

#ifndef __DTXColorClass
#error Attempting to compile on an unsupported platform.
#endif

#endif /* DTXColorCommon_h */
