//
//  DTXLoggingRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 28/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXLoggingRecorder.h"
#import "DTXProfiler.h"
#import <pthread.h>

static dispatch_queue_t __log_queue;
static dispatch_io_t __log_io;
int DTXStdErr;
static int __pipe[2];

static NSMutableArray<__kindof DTXProfiler*>* __recordingProfilers;
static pthread_mutex_t __recordingProfilersMutex;

@implementation DTXLoggingRecorder

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__recordingProfilers = [NSMutableArray new];
		pthread_mutex_init(&__recordingProfilersMutex, NULL);
		[self _redirectLogOutput];
	});
}

+ (void)_redirectLogOutput
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
			
			DTXProfilerAddLogLineWithObjects(logLine, nil);
			
			return true;
		});
	});
}

@end
