//
//  Impl.c
//  DTXProfilerShim
//
//  Created by Leo Natan (Wix) on 7/24/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wincomplete-implementation"
#pragma clang diagnostic ignored "-Wobjc-property-synthesis"
#pragma clang diagnostic ignored "-Wobjc-property-implementation"

#import <DTXProfilerShim/DTXProfiler.h>
#import "DTXLogging.h"

DTX_CREATE_LOG(ProfilerShim)
#define shim_log_function() dtx_log_debug(@"%s called on shim framework", __FUNCTION__)
#define shim_log_invocation(invocation) dtx_log_debug(@"%@ called on shim framework", NSStringFromSelector(invocation.selector))

@implementation DTXProfilingConfiguration

- (void)__something {}
- (void)__setSomething:(id)something {}

+ (instancetype)defaultProfilingConfiguration
{
	shim_log_function();
	
	return [self new];
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	shim_log_function();
	
	return [self new];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if([NSStringFromSelector(aSelector) hasSuffix:@":"])
	{
		return [self.class instanceMethodSignatureForSelector:@selector(__setSomething:)];
	}
	
	return [self.class instanceMethodSignatureForSelector:@selector(__something)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	shim_log_invocation(anInvocation);
}

@end

@implementation DTXMutableProfilingConfiguration

- (void)__something {}
- (void)__setSomething:(id)something {}

+ (instancetype)defaultProfilingConfiguration
{
	shim_log_function();
	return [self new];
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	shim_log_function();
	return [self new];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if([NSStringFromSelector(aSelector) hasSuffix:@":"])
	{
		return [self.class instanceMethodSignatureForSelector:@selector(__setSomething:)];
	}
	
	return [self.class instanceMethodSignatureForSelector:@selector(__something)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	shim_log_invocation(anInvocation);
}

@end

@implementation DTXProfiler

- (void)__something {}
- (void)__setSomething:(id)something {}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if([NSStringFromSelector(aSelector) hasSuffix:@":"])
	{
		return [self.class instanceMethodSignatureForSelector:@selector(__setSomething:)];
	}
	
	return [self.class instanceMethodSignatureForSelector:@selector(__something)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	shim_log_invocation(anInvocation);
}

@end

void DTXProfilerAddTag(NSString* tag)
{
	shim_log_function();
}
void DTXProfilerAddLogLine(NSString* line)
{
	shim_log_function();
}
void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects)
{
	shim_log_function();
}

DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable additionalInfo)
{
	shim_log_function();
	return @"0";
}
void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo)
{
	shim_log_function();
}
void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable additionalInfo)
{
	shim_log_function();
}
