//
//  DTXLoggingRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 28/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXLoggingRecorder.h"
#import "DTXProfiler.h"
#import <pthread.h>
#import "ActivityStreamSPI.h"
@import Darwin;
@import OSLog;

DTX_CREATE_LOG(LoggingRecorder);

static dispatch_queue_t __log_queue;
static dispatch_io_t __log_io;
int DTXStdErr;
static int __pipe[2];

static os_activity_stream_for_pid_t os_activity_stream_for_pid;
static os_activity_stream_resume_t os_activity_stream_resume;
static os_activity_stream_cancel_t os_activity_stream_cancel;
static os_log_copy_formatted_message_t os_log_copy_formatted_message;
static os_activity_stream_set_event_handler_t os_activity_stream_set_event_handler;
static uint8_t (*os_log_get_type)(void *log);

static os_activity_stream_t _stream;

typedef NS_ENUM(uint8_t, DTXOSLogEntryLogLevel) {
	DTXOSLogEntryLogLevelUndefined,
	DTXOSLogEntryLogLevelDebug = 0x2,
	DTXOSLogEntryLogLevelInfo = 0x01,
	DTXOSLogEntryLogLevelNotice = 0x00,
	DTXOSLogEntryLogLevelError = 0x10,
	DTXOSLogEntryLogLevelFault = 0x11,
};

@implementation DTXLoggingRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		BOOL shouldFallbackToLegacy = NO;
		
		void* handle = dlopen("/System/Library/PrivateFrameworks/LoggingSupport.framework/LoggingSupport", RTLD_NOW);
		if(handle == nil)
		{
			shouldFallbackToLegacy = YES;
			goto LEGACY;
		}
		
		os_activity_stream_for_pid = dlsym(handle, "os_activity_stream_for_pid");
		os_activity_stream_resume = dlsym(handle, "os_activity_stream_resume");
		os_activity_stream_cancel = dlsym(handle, "os_activity_stream_cancel");
		os_log_copy_formatted_message = dlsym(handle, "os_log_copy_formatted_message");
		os_activity_stream_set_event_handler = dlsym(handle, "os_activity_stream_set_event_handler");
		os_log_get_type = dlsym(handle, "os_log_get_type");
		
		if(os_activity_stream_for_pid == NULL ||
		   os_activity_stream_resume == NULL ||
		   os_activity_stream_cancel == NULL ||
		   os_log_copy_formatted_message == NULL ||
		   os_activity_stream_set_event_handler == NULL ||
		   os_log_get_type == NULL)
		{
			shouldFallbackToLegacy = YES;
			goto LEGACY;
		}
		
		_stream = os_activity_stream_for_pid(NSProcessInfo.processInfo.processIdentifier, OS_ACTIVITY_STREAM_PROCESS_ONLY | OS_ACTIVITY_STREAM_HISTORICAL | OS_ACTIVITY_STREAM_INFO /* | OS_ACTIVITY_STREAM_DEBUG */, ^ BOOL (os_activity_stream_entry_t entry, int error) {
			if(error != 0 || entry == NULL)
			{
				return YES;
			}
			
			if(entry->type != OS_ACTIVITY_STREAM_TYPE_LOG_MESSAGE)
			{
				return YES;
			}
			
			os_log_message_t log_message = &entry->log_message;
			
			uint8_t log_level = os_log_get_type(log_message);
			
			if(/* log_level == DTXOSLogEntryLogLevelInfo || */ log_level == DTXOSLogEntryLogLevelDebug)
			{
				return YES;
			}
			
			char* msg = os_log_copy_formatted_message(log_message);
			dtx_defer {
				if(msg)
				{
					free(msg);
				}
			};
			
			NSString* message = msg ? @(msg) : nil;
			NSString* subsystem = log_message->subsystem ? @(log_message->subsystem) : nil;
			NSString* category = log_message->category ? @(log_message->category) : nil;
			
			DTXProfilerAddLogEntry([NSDate dateWithTimeIntervalSince1970:log_message->tv_gmt.tv_sec], log_level, subsystem, category, message);
			
			return YES;
		});
		os_activity_stream_resume(_stream);
		
		dtx_log_info(@"Info");
		dtx_log_debug(@"Debug");
		dtx_log_error(@"Error");
		dtx_log_fault(@"Fault");
		
//		NSLog(@"Hey there!");
		return;
		
	LEGACY:
		[self _legacy_redirectLogOutput];
	});
}

+ (void)_legacy_redirectLogOutput
{
	DTXStdErr = dup(STDERR_FILENO);
	
	if (pipe(__pipe) != 0)
	{
		return;
	}
	
	dup2(__pipe[1], STDERR_FILENO);
	close(__pipe[1]);
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
	__log_queue = dtx_dispatch_queue_create_autoreleasing("com.wix.DTXProfilerLogIOQueue", qosAttribute);
	__log_io = dispatch_io_create(DISPATCH_IO_STREAM, __pipe[0], __log_queue, ^(__unused int error) {});
	
	dispatch_io_set_low_water(__log_io, 1);
	
	dispatch_io_read(__log_io, 0, SIZE_MAX, __log_queue, ^(__unused bool done, dispatch_data_t data, __unused int error) {
		if (!data)
		{
			return;
		}
		
		dispatch_data_apply(data, ^bool(__unused dispatch_data_t region, __unused size_t offset, const void *buffer, size_t size)
		{
			write(DTXStdErr, buffer, size);
			
			NSString *logLine = [[NSString alloc] initWithBytes:buffer length:size encoding:NSUTF8StringEncoding];
			
			DTXProfilerAddLegacyLogEntryWithObjects(logLine, nil);
			
			return true;
		});
	});
}

@end
