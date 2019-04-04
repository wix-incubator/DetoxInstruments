//
//  DTXReactNativeProfilerSupport.h
//  DTXProfiler
//
//  Created by Muhammad Abed El Razek on 18/03/2019.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#ifndef DTXReactNativeProfilerSupport_h
#define DTXReactNativeProfilerSupport_h

@import JavaScriptCore;

void DTXInstallRNJSProfilerHooks(JSContext* ctx);
void DTXRegisterRNProfilerCallbacks(void);

#endif /* DTXReactNativeProfilerSupport_h */
