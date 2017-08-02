//
//  DTLogging.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <os/log.h>

#ifdef __OBJC__
#import <Foundation/Foundation.h>

#include "DTXLoggingSubsystem.h"
#ifndef DTX_LOG_SUBSYSTEM
#error No log subsystem defined.
#endif

#define DTX_CREATE_LOG(name) static os_log_t __current_file_log;\
__attribute__((constructor)) \
static void __prepare_log() { \
__current_file_log = os_log_create(DTX_LOG_SUBSYSTEM, #name); \
}

#define dtx_log_debug(format, ...) __dtx_log(__current_file_log, OS_LOG_TYPE_DEBUG, format, ##__VA_ARGS__)
#define dtx_log_info(format, ...) __dtx_log(__current_file_log, OS_LOG_TYPE_INFO, format, ##__VA_ARGS__)
#define dtx_log_error(format, ...) __dtx_log(__current_file_log, OS_LOG_TYPE_ERROR, format, ##__VA_ARGS__)

extern void __dtx_log(os_log_t log, os_log_type_t logType, NSString* format, ...) NS_FORMAT_FUNCTION(3,4);
#endif
