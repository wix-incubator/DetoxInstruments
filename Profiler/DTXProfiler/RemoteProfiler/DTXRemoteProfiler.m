//
//  DTXRemoteProfiler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfiler.h"
#import "AutoCoding.h"
#import "DTXInstruments+CoreDataModel.h"
#import "NSManagedObject+Additions.h"

DTX_CREATE_LOG(RemoteProfiler);

@interface DTXRemoteProfiler () <_DTXProfilerStoryListener>

@end

@implementation DTXRemoteProfiler
{
	DTXSocketConnection* _socketConnection;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self._profilerStoryListener = self;
	}
	
	return self;
}

- (instancetype)initWithOpenSocketConnection:(DTXSocketConnection*)connection remoteProfilerDelegate:(id<DTXRemoteProfilerDelegate>)remoteProfilerDelegate
{
	self = [self init];
	
	if(self)
	{
		_remoteProfilerDelegate = remoteProfilerDelegate;
		
		_socketConnection = connection;
	}
	
	return self;
}

- (void)_serializeCommandWithSelector:(SEL)selector managedObject:(NSManagedObject*)obj additionalParams:(NSArray*)additionalParams
{
	[self _serializeCommandWithSelector:selector dict:obj.dictionaryRepresentationForPropertyList additionalParams:additionalParams];
}

- (void)_serializeCommandWithSelector:(SEL)selector dict:(NSDictionary*)obj additionalParams:(NSArray*)additionalParams
{
	NSMutableDictionary* cmd = [@{@"selector": NSStringFromSelector(selector), @"object": obj} mutableCopy];
	cmd[@"additionalParams"] = additionalParams;
	
	NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
	[_socketConnection writeData:plistData completionHandler:^(NSError * _Nullable error) {
		if(error)
		{
			dtx_log_error(@"Remote profiler hit error: %@", error);
		}
	}];
}

- (void)stopProfilingWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler
{
	[super stopProfilingWithCompletionHandler:^ (NSError* err) {
		[self.remoteProfilerDelegate remoteProfilerDidFinish:self];
		
		if(completionHandler)
		{
			completionHandler(err);
		}
	}];
}

#pragma mark _DTXProfilerStoryListener

- (void)createdOrUpdatedThreadInfo:(DTXThreadInfo *)threadInfo
{
	[self _serializeCommandWithSelector:_cmd managedObject:threadInfo additionalParams:nil];
}

- (void)addLogSample:(DTXLogSample *)logSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:logSample additionalParams:nil];
}

- (void)addPerformanceSample:(__kindof DTXPerformanceSample *)perfrmanceSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:perfrmanceSample additionalParams:nil];
}

- (void)addRNPerformanceSample:(DTXReactNativePeroformanceSample *)rnPerfrmanceSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:rnPerfrmanceSample additionalParams:nil];
}

- (void)createRecording:(DTXRecording *)recording
{
	[self _serializeCommandWithSelector:_cmd managedObject:recording additionalParams:nil];
}

- (void)finishWithResponseForNetworkSample:(DTXNetworkSample *)networkSample
{
	[self _serializeCommandWithSelector:_cmd dict:networkSample.dictionaryRepresentationOfChangedValuesForPropertyList additionalParams:nil];
}

- (void)popSampleGroup:(DTXSampleGroup *)sampleGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:nil];
}

- (void)pushSampleGroup:(DTXSampleGroup *)sampleGroup isRootGroup:(BOOL)isRootGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:@[@{@"isRootGroup": @(isRootGroup)}]];
}

- (void)startRequestWithNetworkSample:(DTXNetworkSample *)networkSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:networkSample additionalParams:nil];
}

- (void)updateRecording:(DTXRecording *)recording stopRecording:(BOOL)stopRecording
{
	[self _serializeCommandWithSelector:_cmd dict:recording.dictionaryRepresentationOfChangedValuesForPropertyList additionalParams:@[@{@"stopRecording": @(stopRecording)}]];
	
	if(stopRecording)
	{
		[_socketConnection closeWrite];
	}
}

- (void)addTag:(DTXTag*)tag
{
	[self _serializeCommandWithSelector:_cmd managedObject:tag additionalParams:nil];
}

@end
