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
#import "DTXRemoteProfilingBasics.h"
#import "DTXRNJSCSourceMapsSupport.h"

DTX_CREATE_LOG(RemoteProfiler);

@interface DTXRemoteProfiler () <DTXProfilerStoryListener>

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

- (instancetype)initWithOpenedSocketConnection:(DTXSocketConnection*)connection remoteProfilerDelegate:(id<DTXRemoteProfilerDelegate>)remoteProfilerDelegate
{
	self = [self init];
	
	if(self)
	{
		_remoteProfilerDelegate = remoteProfilerDelegate;
		
		_socketConnection = connection;
		
		if(self.profilingConfiguration.symbolicateJavaScriptStackTraces)
		{
			DTXRNGetCurrentWorkingSourceMapsData(^(NSData* data) {
				if(data == nil)
				{
					return;
				}
				
				[self _serializeCommandWithSelector:NSSelectorFromString(@"setSourceMapsData:") entityName:@"" dict:@{@"data": data} additionalParams:nil];
			});
		}
	}
	
	return self;
}

- (void)_serializeCommandWithSelector:(SEL)selector managedObject:(NSManagedObject*)obj additionalParams:(NSArray*)additionalParams
{
	[self _serializeCommandWithSelector:selector entityName:obj.entity.name dict:obj.dictionaryRepresentationForPropertyList additionalParams:additionalParams];
}

- (void)_serializeCommandWithSelector:(SEL)selector entityName:(NSString*)entityName dict:(NSDictionary*)obj additionalParams:(NSArray*)additionalParams
{
	NSMutableDictionary* cmd = [@{@"cmdType": @(DTXRemoteProfilingCommandTypeProfilingStoryEvent), @"entityName": entityName, @"selector": NSStringFromSelector(selector), @"object": obj} mutableCopy];
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

- (void)addPerformanceSample:(__kindof DTXPerformanceSample *)performanceSample
{
	if(self.profilingConfiguration.collectStackTraces && self.profilingConfiguration.symbolicateStackTraces && [performanceSample stackTraceIsSymbolicated] == NO)
	{
		[self _symbolicatePerformanceSample:performanceSample];
	}
	
	[self _serializeCommandWithSelector:_cmd managedObject:performanceSample additionalParams:nil];
}

- (void)addRNPerformanceSample:(DTXReactNativePeroformanceSample *)rnPerformanceSample
{
	//Instead of symbolicating here, send source maps data to Detox Instruments for remote symbolication.
	
	[self _serializeCommandWithSelector:_cmd managedObject:rnPerformanceSample additionalParams:nil];
}

- (void)createRecording:(DTXRecording *)recording
{
	NSMutableDictionary* recordingDict = recording.dictionaryRepresentationForPropertyList.mutableCopy;
	NSMutableDictionary* configuration = [recordingDict[@"profilingConfiguration"] mutableCopy];
	configuration[@"recordingFileName"] = self.profilingConfiguration.recordingFileURL.path;
	recordingDict[@"profilingConfiguration"] = configuration;
	
	[self _serializeCommandWithSelector:_cmd entityName:recording.entity.name dict:recordingDict additionalParams:nil];
}

- (void)finishWithResponseForNetworkSample:(DTXNetworkSample *)networkSample
{
	NSMutableDictionary* dict = [networkSample.dictionaryRepresentationOfChangedValuesForPropertyList mutableCopy];
	dict[@"sampleIdentifier"] = networkSample.sampleIdentifier;
	
	[self _serializeCommandWithSelector:_cmd entityName:networkSample.entity.name dict:dict additionalParams:nil];
}

- (void)popSampleGroup:(DTXSampleGroup *)sampleGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:nil];
}

- (void)pushSampleGroup:(DTXSampleGroup *)sampleGroup isRootGroup:(BOOL)isRootGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:@[@(isRootGroup)]];
}

- (void)startRequestWithNetworkSample:(DTXNetworkSample *)networkSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:networkSample additionalParams:nil];
}

- (void)updateRecording:(DTXRecording *)recording stopRecording:(BOOL)stopRecording
{
	[self _serializeCommandWithSelector:_cmd entityName:recording.entity.name dict:recording.dictionaryRepresentationOfChangedValuesForPropertyList additionalParams:@[@(stopRecording)]];
	
	if(stopRecording)
	{
		[_socketConnection closeWrite];
	}
}

- (void)addTagSample:(DTXTag*)tag
{
	[self _serializeCommandWithSelector:_cmd managedObject:tag additionalParams:nil];
}

@end
