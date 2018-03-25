//
//  DTXProfiler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfiler-Private.h"
#import "AutoCoding.h"
#import "DTXInstruments+CoreDataModel.h"
#import "NSManagedObject+Additions.h"
#import "DTXPerformanceSampler.h"
#import "DTXZipper.h"
#import "NSManagedObjectContext+PerformQOSBlock.h"
#import "DTXNetworkRecorder.h"
#import "DTXLoggingRecorder.h"
#import "DTXPollingManager.h"
#import "DTXReactNativeSampler.h"
#import "DTXRNJSCSourceMapsSupport.h"
#import "DTXAddressInfo.h"
#import "DTXDeviceInfo.h"

#define DTX_ASSERT_RECORDING NSAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING NSAssert(self.recording == NO, @"A recording is already in progress");
#define DTX_IGNORE_NOT_RECORDING if(self.recording == NO) { return; }

DTX_CREATE_LOG(Profiler);

@interface DTXProfiler () <DTXNetworkListener, DTXLoggingListener>

@property (atomic, assign, readwrite, getter=isRecording) BOOL recording;

@end

@implementation DTXProfiler
{
	DTXProfilingConfiguration* _currentProfilingConfiguration;
	
	DTXPollingManager* _pollingManager;
	
	NSPersistentContainer* _container;
	NSManagedObjectContext* _backgroundContext;
	
	DTXRecording* _currentRecording;
	DTXSampleGroup* _rootSampleGroup;
	DTXSampleGroup* _currentSampleGroup;
	
	NSMutableArray<DTXSample*>* _pendingSamples;
	
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
}

@synthesize _profilerStoryListener = _profilerStoryListener;

+ (NSString *)version
{
	return [NSString stringWithFormat:@"%@.%@", [[NSBundle bundleForClass:self] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle bundleForClass:self] objectForInfoDictionaryKey:@"CFBundleVersion"]];
}

- (DTXProfilingConfiguration *)profilingConfiguration
{
	return _currentProfilingConfiguration;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	DTX_ASSERT_NOT_RECORDING

	dtx_log_info(@"Starting profiling");
	
	self.recording = YES;
	
	_currentProfilingConfiguration = [configuration copy];
	
	_pendingSamples = [NSMutableArray new];
	
	[[NSFileManager defaultManager] createDirectoryAtURL:configuration.recordingFileURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[configuration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXProfiler class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	_threads = [NSMutableDictionary new];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		_backgroundContext = _container.newBackgroundContext;
		
		[_backgroundContext performBlockAndWait:^{
			_currentRecording = [[DTXRecording alloc] initWithContext:_backgroundContext];
			_currentRecording.profilingConfiguration = configuration.dictionaryRepresentation;
			
			NSDictionary* deviceInfo = [DTXDeviceInfo deviceInfoDictionary];
			[deviceInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
				[_currentRecording setValue:obj forKey:key];
			}];
			
			[_profilerStoryListener createRecording:_currentRecording];
			
			_rootSampleGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
			_rootSampleGroup.name = @"DTXRoot";
			_rootSampleGroup.recording = _currentRecording;
			_currentSampleGroup = _rootSampleGroup;
			
			[_profilerStoryListener pushSampleGroup:_rootSampleGroup isRootGroup:YES];
			
			__weak __typeof(self) weakSelf = self;
			
			_pollingManager = [[DTXPollingManager alloc] initWithInterval:configuration.samplingInterval];
			[_pollingManager addPollable:[[DTXPerformanceSampler alloc] initWithConfiguration:configuration] handler:^(DTXPerformanceSampler* pollable) {
				[weakSelf performanceSamplerDidPoll:pollable];
			}];
			[_pollingManager resume];
			
			if(configuration.recordNetwork == YES)
			{
				[DTXNetworkRecorder addNetworkListener:self];
			}
			
			if(configuration.recordLogOutput == YES)
			{
				[DTXLoggingRecorder addLoggingListener:self];
			}
			
			if(_currentRecording.hasReactNative == YES && _currentProfilingConfiguration.profileReactNative == YES)
			{
				DTXReactNativeSampler* rnSampler = [[DTXReactNativeSampler alloc] initWithConfiguration:configuration];
				if(rnSampler != nil)
				{
					[_pollingManager addPollable:rnSampler handler:^(DTXReactNativeSampler* pollable) {
						[weakSelf reactNativeSamplerDidPoll:pollable];
					}];
				}
			}
			
			dtx_log_info(@"Started profiling");
		} qos:QOS_CLASS_USER_INTERACTIVE];
	}];
}

- (void)_symbolicateStackTracesInternal
{
	NSPredicate* unsymbolicated = [NSPredicate predicateWithFormat:@"stackTraceIsSymbolicated == NO"];
	NSFetchRequest* fr = [DTXAdvancedPerformanceSample fetchRequest];
	fr.predicate = unsymbolicated;
	
	NSArray<DTXAdvancedPerformanceSample*>* unsymbolicatedSamples = [_backgroundContext executeFetchRequest:fr error:NULL];
	[unsymbolicatedSamples enumerateObjectsUsingBlock:^(DTXAdvancedPerformanceSample * _Nonnull unsymbolicatedSample, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _symbolicatePerformanceSample:unsymbolicatedSample];
	}];
}

- (void)_symbolicatePerformanceSample:(DTXAdvancedPerformanceSample *)unsymbolicatedSample
{
	NSMutableArray* symbolicatedStackTrace = [NSMutableArray new];
	
	[unsymbolicatedSample.heaviestStackTrace enumerateObjectsUsingBlock:^(NSNumber* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXAddressInfo* addressInfo = [[DTXAddressInfo alloc] initWithAddress:obj.unsignedIntegerValue];
		[symbolicatedStackTrace addObject:[addressInfo dictionaryRepresentation]];
	}];
	
	unsymbolicatedSample.heaviestStackTrace = symbolicatedStackTrace;
	unsymbolicatedSample.stackTraceIsSymbolicated = YES;
}

- (void)_symbolicateJavaScriptStackTracesInternal
{
	NSPredicate* unsymbolicated = [NSPredicate predicateWithFormat:@"stackTraceIsSymbolicated == NO"];
	NSFetchRequest* fr = [DTXReactNativePeroformanceSample fetchRequest];
	fr.predicate = unsymbolicated;
	
	NSArray<DTXReactNativePeroformanceSample*>* unsymbolicatedSamples = [_backgroundContext executeFetchRequest:fr error:NULL];
	[unsymbolicatedSamples enumerateObjectsUsingBlock:^(DTXReactNativePeroformanceSample * _Nonnull unsymbolicatedSample, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _symbolicateRNPerformanceSample:unsymbolicatedSample];
	}];
}

- (void)_symbolicateRNPerformanceSample:(DTXReactNativePeroformanceSample *)unsymbolicatedSample
{
	BOOL wasSymbolicated = NO;
	
	unsymbolicatedSample.stackTrace = DTXRNSymbolicateJSCBacktrace(unsymbolicatedSample.stackTrace, &wasSymbolicated);
	unsymbolicatedSample.stackTraceIsSymbolicated = wasSymbolicated;
}

- (void)stopProfilingWithCompletionHandler:(void(^ __nullable)(NSError* __nullable error))handler
{
	DTX_ASSERT_RECORDING
	
	dtx_log_info(@"Stopping profiling");
	
	[self _flushPendingSamplesWithInternalCompletionHandler:^{
		_currentRecording.endTimestamp = [NSDate date];
		
		[_profilerStoryListener updateRecording:_currentRecording stopRecording:YES];
		
		_pollingManager = nil;
		
		if(_currentProfilingConfiguration.collectStackTraces == YES
		   && _currentProfilingConfiguration.symbolicateStackTraces == YES)
		{
			[self _symbolicateStackTracesInternal];
		}
		
		if(_currentRecording.hasReactNative
		   && _currentProfilingConfiguration.profileReactNative == YES
		   && _currentProfilingConfiguration.collectJavaScriptStackTraces == YES
		   && _currentProfilingConfiguration.symbolicateJavaScriptStackTraces == YES)
		{
			[self _symbolicateJavaScriptStackTracesInternal];
		}
		
		if(_currentProfilingConfiguration.recordNetwork == YES)
		{
			[DTXNetworkRecorder removeNetworkListener:self];
		}
		
		if(_currentProfilingConfiguration.recordLogOutput == YES)
		{
			[DTXLoggingRecorder removeLoggingListener:self];
		}
		
		[_backgroundContext save:NULL];
		
		[self _closeContainerInternal];
		
		_currentProfilingConfiguration = nil;
		self.recording = NO;
		
		dtx_log_info(@"Stopped profiling");
		
		if(handler != nil)
		{
			handler(nil);
		}
	}];
}

- (void)pushSampleGroupWithName:(NSString*)name
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		DTXSampleGroup* newGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
		newGroup.name = name;
		newGroup.parentGroup = _currentSampleGroup;
		[_profilerStoryListener pushSampleGroup:newGroup isRootGroup:NO];
		_currentSampleGroup = newGroup;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)popSampleGroup
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		NSAssert(_currentSampleGroup.parentGroup != nil, @"Cannot pop the root sample group");
		
		_currentSampleGroup.closeTimestamp = [NSDate date];
		[_profilerStoryListener popSampleGroup:_currentSampleGroup];
		_currentSampleGroup = _currentSampleGroup.parentGroup;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)addTag:(NSString*)_tag
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXTag* tag = [[DTXTag alloc] initWithContext:_backgroundContext];
		tag.parentGroup = _currentSampleGroup;
		tag.name = _tag;
		
		[_profilerStoryListener addTagSample:tag];
		
		[self _addPendingSampleInternal:tag];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)addLogLine:(NSString *)line
{
	[self addLogLine:line objects:nil];
}

- (void)addLogLine:(NSString *)line objects:(NSArray *)objects
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXLogSample* log = [[DTXLogSample alloc] initWithContext:_backgroundContext];
		log.parentGroup = _currentSampleGroup;
		log.line = line;
		log.objects = objects;
		[_profilerStoryListener addLogSample:log];
		[self _addPendingSampleInternal:log];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_flushPendingSamplesInternal
{
	[_backgroundContext save:NULL];
	[_pendingSamples enumerateObjectsUsingBlock:^(DTXSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_backgroundContext refreshObject:obj mergeChanges:YES];
	}];
	
	[_backgroundContext refreshObject:_currentSampleGroup mergeChanges:YES];
	
	[_pendingSamples removeAllObjects];
}

- (void)_flushPendingSamplesWithInternalCompletionHandler:(void(^)(void))completionHandler
{
	[_backgroundContext performBlock:^{
		[self _flushPendingSamplesInternal];
		
		if(completionHandler)
		{
			completionHandler();
		}
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_closeContainerInternal
{
//	NSJSONWritingOptions jsonOptions = 0;
//	if(_currentProfilingConfiguration.prettyPrintJSONOutput == YES)
//	{
//		jsonOptions |= NSJSONWritingPrettyPrinted;
//	}
//	
//	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[_currentRecording dictionaryRepresentationForJSON] options:jsonOptions error:NULL];
//	NSURL* jsonURL = [_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.json"];
//	[jsonData writeToURL:jsonURL atomically:YES];
	
	NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:[_currentRecording dictionaryRepresentationForPropertyList] format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
	NSURL* plistURL = [_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.plist"];
	[plistData writeToURL:plistURL atomically:YES];
	
	[_container.persistentStoreCoordinator.persistentStores.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
	DTXWriteZipFileWithDirectoryContents([_currentProfilingConfiguration.recordingFileURL URLByAppendingPathExtension:@"zip"], _currentProfilingConfiguration.recordingFileURL);
	
	_container = nil;
}

- (void)performanceSamplerDidPoll:(DTXPerformanceSampler*)performanceSampler
{
	DTX_IGNORE_NOT_RECORDING
	
	DTXCPUMeasurement* cpu = performanceSampler.currentCPU;
	CGFloat memory = performanceSampler.currentMemory;
	CGFloat fps = performanceSampler.currentFPS;
	uint64_t diskReads = performanceSampler.currentDiskReads;
	uint64_t diskWrites = performanceSampler.currentDiskWrites;
	uint64_t diskReadsDelta = performanceSampler.currentDiskReadsDelta;
	uint64_t diskWritesDelta = performanceSampler.currentDiskWritesDelta;
	
	NSArray* stackTrace = performanceSampler.callStackSymbols;
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		__kindof DTXPerformanceSample* perfSample;
		
		if(_currentProfilingConfiguration.recordThreadInformation)
		{
			perfSample = [[DTXAdvancedPerformanceSample alloc] initWithContext:_backgroundContext];
		}
		else
		{
			perfSample = [[DTXPerformanceSample alloc] initWithContext:_backgroundContext];
		}
		
		perfSample.cpuUsage = cpu.totalCPU;
		perfSample.memoryUsage = memory;
		perfSample.fps = fps;
		perfSample.diskReads = diskReads;
		perfSample.diskReadsDelta = diskReadsDelta;
		perfSample.diskWrites = diskWrites;
		perfSample.diskWritesDelta = diskWritesDelta;
		
		if(_currentProfilingConfiguration.recordThreadInformation)
		{
			[cpu.threads enumerateObjectsUsingBlock:^(DTXThreadMeasurement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				DTXThreadInfo* threadInfo = _threads[@(obj.identifier)];
				if(threadInfo == nil)
				{
					threadInfo = [[DTXThreadInfo alloc] initWithContext:_backgroundContext];
					threadInfo.number = _threads.count;
					_threads[@(obj.identifier)] = threadInfo;
					threadInfo.recording = _currentRecording;
				}
				threadInfo.name = obj.name;
				
				[_profilerStoryListener createdOrUpdatedThreadInfo:threadInfo];
				
				DTXThreadPerformanceSample* threadSample = [[DTXThreadPerformanceSample alloc] initWithContext:_backgroundContext];
				threadSample.cpuUsage = obj.cpu;
				threadSample.threadInfo = threadInfo;
				threadSample.advancedPerformanceSample = (DTXAdvancedPerformanceSample*)perfSample;
			}];
			
			if(_currentProfilingConfiguration.collectStackTraces)
			{
				[perfSample setHeaviestStackTrace:stackTrace];
				[perfSample setStackTraceIsSymbolicated:NO];
			}
		}
		
		perfSample.parentGroup = _currentSampleGroup;
		
		[_profilerStoryListener addPerformanceSample:perfSample];
		
		[self _addPendingSampleInternal:perfSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)reactNativeSamplerDidPoll:(DTXReactNativeSampler*) rnSampler
{
	DTX_IGNORE_NOT_RECORDING
	
	double cpu = rnSampler.cpu;
	uint64_t bridgeNToJSCallCount = rnSampler.bridgeNToJSCallCount;
	uint64_t bridgeNToJSCallCountDelta = rnSampler.bridgeNToJSCallCountDelta;
	uint64_t bridgeJSToNCallCount = rnSampler.bridgeJSToNCallCount;
	uint64_t bridgeJSToNCallCountDelta = rnSampler.bridgeJSToNCallCountDelta;
	uint64_t bridgeNToJSDataSize = rnSampler.bridgeNToJSDataSize;
	uint64_t bridgeNToJSDataSizeDelta = rnSampler.bridgeNToJSDataSizeDelta;
	uint64_t bridgeJSToNDataSize = rnSampler.bridgeJSToNDataSize;
	uint64_t bridgeJSToNDataSizeDelta = rnSampler.bridgeJSToNDataSizeDelta;
	
	NSArray* stackTrace = [rnSampler.currentStackTrace componentsSeparatedByString:@"\n"];
	BOOL isSymbolicated = rnSampler.currentStackTraceSymbolicated;
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXReactNativePeroformanceSample* rnPerfSample = [[DTXReactNativePeroformanceSample alloc] initWithContext:_backgroundContext];
		rnPerfSample.cpuUsage = cpu;
		rnPerfSample.bridgeNToJSCallCount = bridgeNToJSCallCount;
		rnPerfSample.bridgeNToJSCallCountDelta = bridgeNToJSCallCountDelta;
		rnPerfSample.bridgeJSToNCallCount = bridgeJSToNCallCount;
		rnPerfSample.bridgeJSToNCallCountDelta = bridgeJSToNCallCountDelta;
		rnPerfSample.bridgeNToJSDataSize = bridgeNToJSDataSize;
		rnPerfSample.bridgeNToJSDataSizeDelta = bridgeNToJSDataSizeDelta;
		rnPerfSample.bridgeJSToNDataSize = bridgeJSToNDataSize;
		rnPerfSample.bridgeJSToNDataSizeDelta = bridgeJSToNDataSizeDelta;
		
		rnPerfSample.stackTrace = stackTrace;
		rnPerfSample.stackTraceIsSymbolicated = isSymbolicated;
		
		rnPerfSample.parentGroup = _currentSampleGroup;
		
		[_profilerStoryListener addRNPerformanceSample:rnPerfSample];
		
		[self _addPendingSampleInternal:rnPerfSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_addPendingSampleInternal:(DTXSample*)pendingSample
{
	[_pendingSamples addObject:pendingSample];
	
	if(_pendingSamples.count >= _currentProfilingConfiguration.numberOfSamplesBeforeFlushToDisk)
	{
		[self _flushPendingSamplesInternal];
	}
}

#pragma mark DTXNetworkListener

- (void)networkRecorderDidStartRequest:(NSURLRequest *)request uniqueIdentifier:(NSString *)uniqueIdentifier
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_currentProfilingConfiguration.recordLocalhostNetwork == NO && ([request.URL.host isEqualToString:@"localhost"] || [request.URL.host isEqualToString:@"127.0.0.1"]))
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXNetworkSample* networkSample = [[DTXNetworkSample alloc] initWithContext:_backgroundContext];
		networkSample.uniqueIdentifier = uniqueIdentifier;
		networkSample.url = request.URL.absoluteString;
		networkSample.requestTimeoutInterval = request.timeoutInterval;
		networkSample.requestHTTPMethod = request.HTTPMethod;
		networkSample.requestHeaders = request.allHTTPHeaderFields;
		
		DTXNetworkData* requestData = [[DTXNetworkData alloc] initWithContext:_backgroundContext];
		requestData.data = request.HTTPBody;
		networkSample.requestData = requestData;
		networkSample.requestDataLength = request.HTTPBody.length + request.allHTTPHeaderFields.description.length;
		
		networkSample.parentGroup = _currentSampleGroup;
		
		[_profilerStoryListener startRequestWithNetworkSample:networkSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)netwrokRecorderDidFinishWithResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error forRequestWithUniqueIdentifier:(NSString *)uniqueIdentifier
{
	if(_currentProfilingConfiguration.recordLocalhostNetwork == NO && ([response.URL.host isEqualToString:@"localhost"] || [response.URL.host isEqualToString:@"127.0.0.1"]))
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
		fr.predicate = [NSPredicate predicateWithFormat:@"uniqueIdentifier == %@", uniqueIdentifier];
		DTXNetworkSample* networkSample = [_backgroundContext executeFetchRequest:fr error:NULL].firstObject;
		if(networkSample == nil)
		{
			return;
		}
		
		networkSample.responseTimestamp = [NSDate date];
		
		networkSample.responseError = error.localizedDescription;
		networkSample.responseMIMEType = response.MIMEType;
		if([response isKindOfClass:[NSHTTPURLResponse class]])
		{
			NSHTTPURLResponse* httpResponse = (id)response;
			
			networkSample.responseStatusCode = httpResponse.statusCode;
			networkSample.responseStatusCodeString = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
			networkSample.responseHeaders = httpResponse.allHeaderFields;
		}
		
		DTXNetworkData* responseData = [[DTXNetworkData alloc] initWithContext:_backgroundContext];
		responseData.data = data;
		networkSample.responseData = responseData;
		networkSample.responseDataLength = data.length + networkSample.responseHeaders.description.length;
		
		networkSample.totalDataLength = networkSample.requestDataLength + networkSample.responseDataLength;
		
		[_profilerStoryListener finishWithResponseForNetworkSample:networkSample];
		
		[self _addPendingSampleInternal:networkSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

#pragma DTXLoggingListener

- (void)loggingRecorderDidAddLogLine:(NSString *)logLine objects:(NSArray*)objects
{
	[self addLogLine:logLine objects:objects];
}

@end
