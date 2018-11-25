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

@implementation DTXProfilingConfiguration

- (void)__something {}
- (void)__setSomething:(id)something {}

+ (instancetype)defaultProfilingConfiguration
{
	return [self new];
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
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
	
}

@end

@implementation DTXMutableProfilingConfiguration

- (void)__something {}
- (void)__setSomething:(id)something {}

+ (instancetype)defaultProfilingConfiguration
{
	return [self new];
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
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
	
}

@end

void DTXProfilerAddTag(NSString* tag)
{
	
}
void DTXProfilerAddLogLine(NSString* line)
{
	
}
void DTXProfilerAddLogLineWithObjects(NSString* line, NSArray* __nullable objects)
{
	
}

DTXEventIdentifier DTXProfilerMarkEventIntervalBegin(NSString* category, NSString* name, NSString* __nullable additionalInfo)
{
	return @"0";
}
void DTXProfilerMarkEventIntervalEnd(NSString* identifier, DTXEventStatus eventStatus, NSString* __nullable additionalInfo)
{
	
}
void DTXProfilerMarkEvent(NSString* category, NSString* name, DTXEventStatus eventStatus, NSString* __nullable additionalInfo)
{
	
}
