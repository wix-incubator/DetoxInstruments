//
//  DTXLoggingRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 28/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXLoggingRecorder.h"
#import "DTXProfiler.h"
#import <pthread.h>
#import "DTXLiveLogStreamer.h"

DTX_CREATE_LOG(LoggingRecorder);

DTXLiveLogStreamer* _streamer;

static dispatch_queue_t __log_queue;
static dispatch_io_t __log_io;
int DTXStdErr;
static int __pipe[2];

@implementation DTXLoggingRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_streamer = [DTXLiveLogStreamer new];
		if(_streamer == nil)
		{
			goto LEGACY;
		}
		
		[_streamer startLoggingWithHandler:^(BOOL isFromProcess, const char *proc_imagepath, BOOL isFromApple, NSDate * _Nonnull timestamp, DTXOSLogEntryLogLevel level, NSString * __nullable subsystem, NSString * __nullable category, NSString * _Nonnull message) {
			DTXProfilerAddLogEntry(timestamp, (DTXProfilerLogLevel)level, subsystem, category, message);
		}];
		
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
