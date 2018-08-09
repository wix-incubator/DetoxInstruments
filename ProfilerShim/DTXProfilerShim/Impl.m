//
//  Impl.c
//  DTXProfilerShim
//
//  Created by Leo Natan (Wix) on 7/24/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <DTXProfilerShim/DTXProfiler.h>

@implementation DTXProfilingConfiguration

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
	return self;
}

- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
	return [DTXMutableProfilingConfiguration new];
}

+ (instancetype)defaultProfilingConfiguration
{
	return [self new];
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	return [self new];
}

- (NSURL *)recordingFileURL
{
	return [NSURL fileURLWithPath:@"/dev/null"];
}

@end

@implementation DTXMutableProfilingConfiguration

@synthesize samplingInterval;
@synthesize numberOfSamplesBeforeFlushToDisk;
@synthesize collectOpenFileNames;
@synthesize recordNetwork;
@synthesize recordLocalhostNetwork;
@synthesize recordThreadInformation;
@synthesize collectStackTraces;
@synthesize symbolicateStackTraces;
@synthesize recordLogOutput;
@synthesize profileReactNative;
@synthesize collectJavaScriptStackTraces;
@synthesize symbolicateJavaScriptStackTraces;
@synthesize prettyPrintJSONOutput;
@synthesize recordingFileURL;
- (void)setRecordingFileURL:(NSURL *)recordingFileURL
{
	
}
- (NSURL *)recordingFileURL
{
	return [NSURL fileURLWithPath:@"/dev/null"];
}

@end

@implementation DTXProfiler

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	
}

- (void)stopProfilingWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	completionHandler([NSError errorWithDomain:NSInternalInconsistencyException code:0 userInfo:@{NSLocalizedDescriptionKey: @"Shim Profiler framework used"}]);
}

+ (NSString *)version
{
	return @"0.0";
}

@end

void DTXProfilerPushSampleGroup(NSString* name)
{
	
}
void DTXProfilerPopSampleGroup(void)
{
	
}
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

//__attribute__((visibility("hidden")))
__attribute__((unused))
void unused_func(void)
{
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration defaultProfilingConfiguration];
	
	DTXProfiler* profiler = [[DTXProfiler alloc] init];
	[profiler startProfilingWithConfiguration:config];
	
	NSString* x = DTXProfilerMarkEventIntervalBegin(@"1", @"2", @"3");
	DTXProfilerMarkEventIntervalEnd(x, 0, @"4");
	DTXProfilerMarkEvent(@"5", @"6", 7, @"8");
	
	DTXProfilerPushSampleGroup(@"9");
	DTXProfilerPopSampleGroup();
	DTXProfilerAddTag(@"10");
	DTXProfilerAddLogLine(@"11");
	DTXProfilerAddLogLineWithObjects(@"12", @[@"13"]);
}
