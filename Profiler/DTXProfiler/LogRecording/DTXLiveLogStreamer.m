//
//  DTXLiveLogStreamer.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 8/27/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXLiveLogStreamer.h"
#import "ActivityStreamSPI.h"
@import Darwin;

static os_activity_stream_for_pid_t os_activity_stream_for_pid;
static os_activity_stream_resume_t os_activity_stream_resume;
static os_activity_stream_cancel_t os_activity_stream_cancel;
static os_log_copy_formatted_message_t os_log_copy_formatted_message;
static os_activity_stream_set_event_handler_t os_activity_stream_set_event_handler;
static uint8_t (*os_log_get_type)(void *log);

@implementation DTXLiveLogStreamer
{
	os_activity_stream_t _stream;
}

static BOOL wasLoaded = NO;
- (instancetype)init
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		void* handle = dlopen("/System/Library/PrivateFrameworks/LoggingSupport.framework/LoggingSupport", RTLD_NOW);
		if(handle == nil)
		{
			return;
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
			return;
		}
		
		wasLoaded = YES;
	});
	
	if(wasLoaded == NO)
	{
		return nil;
	}
	
	self = [super init];
	
	if(self)
	{
		_processOnly = YES;
		_allowsInfo = YES;
		_allowsDebug = YES;
		_allowsApple = NO;
	}
	
	return wasLoaded ? self : nil;
}

- (void)startLoggingWithHandler:(void (^)(BOOL isFromProcess, const char *proc_imagepath, BOOL isFromApple, NSDate * _Nonnull, DTXOSLogEntryLogLevel, NSString * _Nonnull, NSString * _Nonnull, NSString * _Nonnull))handler
{
	os_activity_stream_flag_t flags = 0;
	if(self.processOnly)
	{
		flags |= OS_ACTIVITY_STREAM_PROCESS_ONLY;
	}
	if(self.allowsDebug)
	{
		flags |= OS_ACTIVITY_STREAM_DEBUG;
	}
	if(self.allowsInfo)
	{
		flags |= OS_ACTIVITY_STREAM_INFO;
	}
	
	__weak __typeof(self) weakSelf = self;
	pid_t current_pid = NSProcessInfo.processInfo.processIdentifier;
	
	_stream = os_activity_stream_for_pid(self.processOnly ? current_pid : -1, flags, ^ BOOL (os_activity_stream_entry_t entry, int error) {
		if(error != 0 || entry == NULL)
		{
			return YES;
		}
		
		if(entry->type != OS_ACTIVITY_STREAM_TYPE_LOG_MESSAGE)
		{
			return YES;
		}
		
		os_log_message_t log_message = &entry->log_message;
		
		NSString* subsystem = log_message->subsystem ? @(log_message->subsystem) : nil;
		BOOL isFromApple = [subsystem hasPrefix:@"com.apple"] || [@(log_message->image_path) containsString:@"simruntime"];
		if(weakSelf.allowsApple == NO && isFromApple == YES)
		{
			return YES;
		}
		
		uint8_t log_level = os_log_get_type(log_message);
		
		char* msg = os_log_copy_formatted_message(log_message);
		dtx_defer {
			if(msg)
			{
				free(msg);
			}
		};
		
		NSString* message = msg ? @(msg) : nil;
		NSString* category = log_message->category ? @(log_message->category) : nil;
		
		handler(entry->pid == current_pid, entry->proc_imagepath, isFromApple, [NSDate dateWithTimeIntervalSince1970:(double)log_message->tv_gmt.tv_sec + (double)log_message->tv_gmt.tv_usec / 1.e6], log_level, subsystem, category, message);
		
		return YES;
	});
	os_activity_stream_resume(_stream);
}

- (void)dealloc
{
	if(_stream)
	{
		os_activity_stream_cancel(_stream);
		_stream = nil;
	}
}

@end
