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
#import "DTXSignpostSample+CoreDataClass.h"
#import "DTXReactNativeEventsRecorder.h"

#define DTX_ASSERT_RECORDING NSAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING NSAssert(self.recording == NO, @"A recording is already in progress");
#define DTX_IGNORE_NOT_RECORDING if(self.recording == NO) { return; }

DTX_CREATE_LOG(Profiler);

@interface DTXProfiler () <DTXNetworkProfilingListener, DTXLoggingListener, DTXReactNativeEventsListener>

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

- (NSPersistentContainer*)_persistentStoreForProfiling
{
	NSError* err;
	[[NSFileManager defaultManager] removeItemAtURL:_currentProfilingConfiguration.recordingFileURL error:&err];
	[[NSFileManager defaultManager] createDirectoryAtURL:_currentProfilingConfiguration.recordingFileURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXProfiler class]]]];
	
	NSPersistentContainer* rv = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	rv.persistentStoreDescriptions = @[description];
	
	return rv;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	DTX_ASSERT_NOT_RECORDING

	dtx_log_info(@"Starting profiling");
	
	self.recording = YES;
	
	_currentProfilingConfiguration = [configuration copy];
	
	_pendingSamples = [NSMutableArray new];
	
	_threads = [NSMutableDictionary new];
	
	_container = [self _persistentStoreForProfiling];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		self->_backgroundContext = self->_container.newBackgroundContext;
		
		[self->_backgroundContext performBlockAndWait:^{
			self->_currentRecording = [[DTXRecording alloc] initWithContext:self->_backgroundContext];
			self->_currentRecording.profilingConfiguration = configuration.dictionaryRepresentation;
			
			NSDictionary* deviceInfo = [DTXDeviceInfo deviceInfo];
			[deviceInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
				[self->_currentRecording setValue:obj forKey:key];
			}];
			
			[self->_profilerStoryListener createRecording:self->_currentRecording];
			
			self->_rootSampleGroup = [[DTXSampleGroup alloc] initWithContext:self->_backgroundContext];
			self->_rootSampleGroup.name = @"DTXRoot";
			self->_rootSampleGroup.recording = self->_currentRecording;
			self->_currentSampleGroup = self->_rootSampleGroup;
			
			[self->_profilerStoryListener pushSampleGroup:self->_rootSampleGroup isRootGroup:YES];
			
			__weak __typeof(self) weakSelf = self;
			
			self->_pollingManager = [[DTXPollingManager alloc] initWithInterval:configuration.samplingInterval];
			[self->_pollingManager addPollable:[[DTXPerformanceSampler alloc] initWithConfiguration:configuration] handler:^(DTXPerformanceSampler* pollable) {
				[weakSelf performanceSamplerDidPoll:pollable];
			}];
			
			if(configuration.recordNetwork == YES)
			{
				[DTXNetworkRecorder addNetworkListener:self];
			}
			
			if(configuration.recordLogOutput == YES)
			{
				[DTXLoggingRecorder addLoggingListener:self];
			}
			
			if(self->_currentRecording.hasReactNative == YES && self->_currentProfilingConfiguration.profileReactNative == YES)
			{
				DTXReactNativeSampler* rnSampler = [[DTXReactNativeSampler alloc] initWithConfiguration:configuration];
				if(rnSampler != nil)
				{
					[self->_pollingManager addPollable:rnSampler handler:^(DTXReactNativeSampler* pollable) {
						[weakSelf reactNativeSamplerDidPoll:pollable];
					}];
				}
				
				[DTXReactNativeEventsRecorder addReactNativeEventsListener:self];
			}
			
			[self->_pollingManager resume];
			
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
		self->_currentRecording.endTimestamp = [NSDate date];
		
		[self->_profilerStoryListener updateRecording:self->_currentRecording stopRecording:YES];
		
		self->_pollingManager = nil;
		
		if(self->_currentProfilingConfiguration.collectStackTraces == YES
		   && self->_currentProfilingConfiguration.symbolicateStackTraces == YES)
		{
			[self _symbolicateStackTracesInternal];
		}
		
		if(self->_currentRecording.hasReactNative
		   && self->_currentProfilingConfiguration.profileReactNative == YES
		   && self->_currentProfilingConfiguration.collectJavaScriptStackTraces == YES
		   && self->_currentProfilingConfiguration.symbolicateJavaScriptStackTraces == YES)
		{
			[self _symbolicateJavaScriptStackTracesInternal];
		}
		
		if(self->_currentProfilingConfiguration.recordNetwork == YES)
		{
			[DTXNetworkRecorder removeNetworkListener:self];
		}
		
		if(self->_currentProfilingConfiguration.recordLogOutput == YES)
		{
			[DTXLoggingRecorder removeLoggingListener:self];
		}
		
		if(self->_currentRecording.hasReactNative
		   && self->_currentProfilingConfiguration.profileReactNative == YES)
		{
			[DTXReactNativeEventsRecorder removeReactNativeEventsListener:self];
		}
		
		[self->_backgroundContext save:NULL];
		
		[self _closeContainerInternal];
		
		self->_container = nil;
		
		self->_currentProfilingConfiguration = nil;
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
		DTXSampleGroup* newGroup = [[DTXSampleGroup alloc] initWithContext:self->_backgroundContext];
		newGroup.name = name;
		newGroup.parentGroup = self->_currentSampleGroup;
		[self->_profilerStoryListener pushSampleGroup:newGroup isRootGroup:NO];
		self->_currentSampleGroup = newGroup;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)popSampleGroup
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		NSAssert(self->_currentSampleGroup.parentGroup != nil, @"Cannot pop the root sample group");
		
		self->_currentSampleGroup.closeTimestamp = [NSDate date];
		[self->_profilerStoryListener popSampleGroup:self->_currentSampleGroup];
		self->_currentSampleGroup = self->_currentSampleGroup.parentGroup;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)addTag:(NSString*)_tag
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXTag* tag = [[DTXTag alloc] initWithContext:self->_backgroundContext];
		tag.parentGroup = self->_currentSampleGroup;
		tag.name = _tag;
		
		[self->_profilerStoryListener addTagSample:tag];
		
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
	
	[self->_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXLogSample* log = [[DTXLogSample alloc] initWithContext:self->_backgroundContext];
		log.parentGroup = self->_currentSampleGroup;
		log.line = line;
		log.objects = objects;
		[self->_profilerStoryListener addLogSample:log];
		[self _addPendingSampleInternal:log];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (NSString*)markEventIntervalBeginWithCategory:(NSString*)category name:(NSString*)name additionalInfo:(nullable NSString*)additionalInfo;
{
	NSString* identifier = NSUUID.UUID.UUIDString;
	
	[self->_backgroundContext performBlock:^{
		DTXSignpostSample* signpostSample = [[DTXSignpostSample alloc] initWithContext:self->_backgroundContext];
		signpostSample.uniqueIdentifier = identifier;
		signpostSample.category = category;
		signpostSample.name = [name copy];
		signpostSample.additionalInfoStart = [additionalInfo copy];
		signpostSample.parentGroup = self->_currentSampleGroup;
		
		[self->_profilerStoryListener markEventIntervalBegin:signpostSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
	
	return identifier;
}

- (void)markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(nullable NSString*)additionalInfo;
{
	[self->_backgroundContext performBlock:^{
		NSFetchRequest* fr = [DTXSignpostSample fetchRequest];
		fr.predicate = [NSPredicate predicateWithFormat:@"uniqueIdentifier == %@", identifier];
		DTXSignpostSample* signpostSample = [self->_backgroundContext executeFetchRequest:fr error:NULL].firstObject;
		if(signpostSample == nil)
		{
			return;
		}

		signpostSample.endTimestamp = [NSDate date];
		signpostSample.duration = [signpostSample.endTimestamp timeIntervalSinceDate:signpostSample.timestamp];
		signpostSample.eventStatus = eventStatus;
		signpostSample.additionalInfoEnd = [additionalInfo copy];
		
		[self->_profilerStoryListener markEventIntervalEnd:signpostSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)markEventWithCategory:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(nullable NSString*)additionalInfo;
{
	[self->_backgroundContext performBlock:^{
		DTXSignpostSample* signpostSample = [[DTXSignpostSample alloc] initWithContext:self->_backgroundContext];
		signpostSample.parentGroup = self->_currentSampleGroup;
		signpostSample.uniqueIdentifier = NSUUID.UUID.UUIDString;
		signpostSample.category = category;
		signpostSample.name = [name copy];
		signpostSample.additionalInfoStart = [additionalInfo copy];
		signpostSample.eventStatus = eventStatus;
		signpostSample.endTimestamp = signpostSample.timestamp;
		signpostSample.isEvent = YES;
		
		[self->_profilerStoryListener markEvent:signpostSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_flushPendingSamplesInternal
{
	[_backgroundContext save:NULL];
	[_pendingSamples enumerateObjectsUsingBlock:^(DTXSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self->_backgroundContext refreshObject:obj mergeChanges:YES];
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
		[self->_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
	DTXWriteZipFileWithDirectoryURL([_currentProfilingConfiguration.recordingFileURL URLByAppendingPathExtension:@"zip"], _currentProfilingConfiguration.recordingFileURL);
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
	
	NSArray* openFiles = performanceSampler.currentOpenFiles;
	
	[_backgroundContext performBlockAndWait:^{
		DTX_IGNORE_NOT_RECORDING
		
		__kindof DTXPerformanceSample* perfSample;
		
		if(self->_currentProfilingConfiguration.recordThreadInformation)
		{
			perfSample = [[DTXAdvancedPerformanceSample alloc] initWithContext:self->_backgroundContext];
		}
		else
		{
			perfSample = [[DTXPerformanceSample alloc] initWithContext:self->_backgroundContext];
		}
		
		perfSample.cpuUsage = cpu.totalCPU;
		perfSample.memoryUsage = memory;
		perfSample.fps = fps;
		perfSample.diskReads = diskReads;
		perfSample.diskReadsDelta = diskReadsDelta;
		perfSample.diskWrites = diskWrites;
		perfSample.diskWritesDelta = diskWritesDelta;
		
		if(self->_currentProfilingConfiguration.collectOpenFileNames)
		{
			perfSample.openFiles = openFiles;
		}
		
		if(self->_currentProfilingConfiguration.recordThreadInformation)
		{
			[cpu.threads enumerateObjectsUsingBlock:^(DTXThreadMeasurement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				DTXThreadInfo* threadInfo = self->_threads[@(obj.identifier)];
				if(threadInfo == nil)
				{
					threadInfo = [[DTXThreadInfo alloc] initWithContext:self->_backgroundContext];
					threadInfo.number = self->_threads.count;
					self->_threads[@(obj.identifier)] = threadInfo;
					threadInfo.recording = self->_currentRecording;
				}
				threadInfo.name = obj.name;
				
				[self->_profilerStoryListener createdOrUpdatedThreadInfo:threadInfo];
				
				DTXThreadPerformanceSample* threadSample = [[DTXThreadPerformanceSample alloc] initWithContext:self->_backgroundContext];
				threadSample.cpuUsage = obj.cpu;
				threadSample.threadInfo = threadInfo;
				threadSample.advancedPerformanceSample = (DTXAdvancedPerformanceSample*)perfSample;
			}];
			
			if(self->_currentProfilingConfiguration.collectStackTraces)
			{
				[perfSample setHeaviestStackTrace:stackTrace];
				[perfSample setStackTraceIsSymbolicated:NO];
			}
		}
		
		perfSample.parentGroup = self->_currentSampleGroup;
		
		[self->_profilerStoryListener addPerformanceSample:perfSample];
		
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
	
	[_backgroundContext performBlockAndWait:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXReactNativePeroformanceSample* rnPerfSample = [[DTXReactNativePeroformanceSample alloc] initWithContext:self->_backgroundContext];
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
		
		rnPerfSample.parentGroup = self->_currentSampleGroup;
		
		[self->_profilerStoryListener addRNPerformanceSample:rnPerfSample];
		
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

#pragma mark DTXNetworkProfilingListener

- (void)networkRecorderDidStartRequest:(NSURLRequest *)request uniqueIdentifier:(NSString *)uniqueIdentifier
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_currentProfilingConfiguration.recordLocalhostNetwork == NO && ([request.URL.host isEqualToString:@"localhost"] || [request.URL.host isEqualToString:@"127.0.0.1"]))
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXNetworkSample* networkSample = [[DTXNetworkSample alloc] initWithContext:self->_backgroundContext];
		networkSample.uniqueIdentifier = uniqueIdentifier;
		networkSample.url = request.URL.absoluteString;
		networkSample.requestTimeoutInterval = request.timeoutInterval;
		networkSample.requestHTTPMethod = request.HTTPMethod;
		networkSample.requestHeaders = request.allHTTPHeaderFields;
		networkSample.requestHeadersFlat = request.allHTTPHeaderFields.debugDescription;
		
		DTXNetworkData* requestData = [[DTXNetworkData alloc] initWithContext:self->_backgroundContext];
		requestData.data = request.HTTPBody;
		networkSample.requestData = requestData;
		networkSample.requestDataLength = request.HTTPBody.length + request.allHTTPHeaderFields.description.length;
		
		networkSample.parentGroup = self->_currentSampleGroup;
		
		[self->_profilerStoryListener startRequestWithNetworkSample:networkSample];
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
		DTXNetworkSample* networkSample = [self->_backgroundContext executeFetchRequest:fr error:NULL].firstObject;
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
			networkSample.responseHeadersFlat = httpResponse.allHeaderFields.debugDescription;
		}
		
		DTXNetworkData* responseData = [[DTXNetworkData alloc] initWithContext:self->_backgroundContext];
		responseData.data = data;
		networkSample.responseData = responseData;
		networkSample.responseDataLength = data.length + networkSample.responseHeaders.description.length;
		
		networkSample.totalDataLength = networkSample.requestDataLength + networkSample.responseDataLength;
		
		[self->_profilerStoryListener finishWithResponseForNetworkSample:networkSample];
		
		[self _addPendingSampleInternal:networkSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

#pragma DTXLoggingListener

- (void)loggingRecorderDidAddLogLine:(NSString *)logLine objects:(NSArray*)objects
{
	[self addLogLine:logLine objects:objects];
}

@end
