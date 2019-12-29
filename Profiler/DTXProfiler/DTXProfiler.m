//
//  DTXProfiler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXProfiler-Private.h"
#import "DTXProfilerAPI-Private.h"
#import "AutoCoding.h"
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
#import "DTXRecording+Additions.h"
#import "NSString+Hashing.h"
#import <Foundation/Foundation.h>

#define DTXAssert(condition, desc, ...)	\
do {				\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (__builtin_expect(!(condition), 0)) {		\
[NSException raise:NSInternalInconsistencyException format:desc]; \
}				\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)

#define DTX_ASSERT_RECORDING DTXAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING DTXAssert(self.recording == NO, @"A recording is already in progress");
#define DTX_IGNORE_NOT_RECORDING if(self.recording == NO) { return; }

DTX_CREATE_LOG(Profiler);

@interface DTXProfiler ()

@property (atomic, assign, readwrite, getter=isRecording) BOOL recording;

@end

@implementation DTXProfiler
{
	DTXProfilingConfiguration* _currentProfilingConfiguration;
	
	DTXPollingManager* _pollingManager;
	
	NSPersistentContainer* _container;
	NSManagedObjectContext* _backgroundContext;
	
	DTXRecording* _currentRecording;
	
	NSMutableArray<DTXSample*>* _pendingSamples;
	NSMapTable<NSString*, DTXNetworkSample*>* _pendingNetworkSamples;
	NSMapTable<NSString*, DTXSignpostSample*>* _pendingSignpostSamples;
	
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
	
	BOOL _awaitsMarkerInsertion;
}

@synthesize _profilerStoryListener = _profilerStoryListener;

static uint64_t main_thread_identifier;
+ (void)load
{
	main_thread_identifier = _DTXThreadIdentifierForCurrentThread();
}

+ (NSString *)version
{
	return [NSString stringWithFormat:@"%@.%@", [[NSBundle bundleForClass:self] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle bundleForClass:self] objectForInfoDictionaryKey:@"CFBundleVersion"]];
}

- (DTXProfilingConfiguration *)profilingConfiguration
{
	return _currentProfilingConfiguration;
}

+ (NSManagedObjectModel*)_modelForProfiler
{
	static NSManagedObjectModel* model;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXProfiler class]]]];
	});
	return model;
}

- (NSPersistentContainer*)_persistentStoreForProfilingDeleteExisting:(BOOL)deleteExisting
{
	NSError* err;
	
	if(deleteExisting)
	{
		[[NSFileManager defaultManager] removeItemAtURL:_currentProfilingConfiguration.recordingFileURL error:&err];
	}
	
	[[NSFileManager defaultManager] createDirectoryAtURL:_currentProfilingConfiguration.recordingFileURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
	
	NSPersistentContainer* rv = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:self.class._modelForProfiler];
	rv.persistentStoreDescriptions = @[description];
	
	return rv;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	[self _startProfilingWithConfiguration:configuration deleteExisting:YES];
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration duration:(NSTimeInterval)duration completionHandler:(void(^ __nullable)(NSError* __nullable error))completionHandler
{
	[self startProfilingWithConfiguration:configuration];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dtx_dispatch_queue_create_autoreleasing("com.wix.DTXJustForLater", NULL), ^{
		[self stopProfilingWithCompletionHandler:completionHandler];
	});
}

- (void)continueProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	[self _startProfilingWithConfiguration:configuration deleteExisting:NO];
}

- (void)_startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration deleteExisting:(BOOL)deleteExisting
{
	DTX_ASSERT_NOT_RECORDING

	dtx_log_info(@"Starting profiling");
	
	self.recording = YES;
	
	_currentProfilingConfiguration = [configuration copy];
	
	if(_currentProfilingConfiguration.recordPerformance == NO && _currentProfilingConfiguration.recordNetwork == NO && _currentProfilingConfiguration.recordEvents == NO && _currentProfilingConfiguration.profileReactNative == NO && _currentProfilingConfiguration.recordActivity == NO)
	{
		[_currentProfilingConfiguration setValue:@YES forKey:@"recordPerformance"];
		[_currentProfilingConfiguration setValue:@YES forKey:@"recordNetwork"];
		[_currentProfilingConfiguration setValue:@YES forKey:@"recordEvents"];
		[_currentProfilingConfiguration setValue:@YES forKey:@"profileReactNative"];
	}
	
	_pendingSamples = [NSMutableArray new];
	_pendingNetworkSamples = [NSMapTable strongToStrongObjectsMapTable];
	_pendingSignpostSamples = [NSMapTable strongToStrongObjectsMapTable];
	
	_threads = [NSMutableDictionary new];
	
	_container = [self _persistentStoreForProfilingDeleteExisting:deleteExisting];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		self->_backgroundContext = self->_container.newBackgroundContext;
		
		[self->_backgroundContext performBlockAndWait:^{
			if(deleteExisting == NO)
			{
				NSFetchRequest* fr = [DTXSample fetchRequest];
				fr.fetchLimit = 1;
				fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
				fr.resultType = NSDictionaryResultType;
				fr.propertiesToFetch = @[@"timestamp"];
				
				NSArray<NSDictionary*>* samples = [self->_backgroundContext executeFetchRequest:fr error:NULL];
				if(samples.count > 0)
				{
					NSDate* sampleTimestamp = samples.firstObject[@"timestamp"];
					
					[self _addMarkerPerformanceSampleAtTimestamp:[sampleTimestamp dateByAddingTimeInterval:0.0001]];
					self->_awaitsMarkerInsertion = YES;
				}
				
				fr = [DTXRecording fetchRequest];
				fr.fetchLimit = 1;
				DTXRecording* anotherRecording = [self->_backgroundContext executeFetchRequest:fr error:NULL].firstObject;
				if(anotherRecording)
				{
					self->_currentProfilingConfiguration = [anotherRecording.dtx_profilingConfiguration copy];
				}
			}
			
			self->_currentRecording = [[DTXRecording alloc] initWithContext:self->_backgroundContext];
			self->_currentRecording.profilingConfiguration = self->_currentProfilingConfiguration.dictionaryRepresentation;
			[self _threadForThreadIdentifier:main_thread_identifier];
			
			NSDictionary* deviceInfo = [DTXDeviceInfo deviceInfo];
			[deviceInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
				if([self->_currentRecording respondsToSelector:NSSelectorFromString(key)])
				{
					[self->_currentRecording setValue:obj forKey:key];
				}
			}];
			
			[self->_profilerStoryListener createRecording:self->_currentRecording];
			
			__weak __typeof(self) weakSelf = self;
			
			BOOL needsPerformancePolling = self->_currentProfilingConfiguration.recordPerformance;
			BOOL needsRNPolling = self->_currentRecording.hasReactNative == YES && self->_currentProfilingConfiguration.profileReactNative == YES;
			
			if(needsPerformancePolling || needsRNPolling)
			{
				self->_pollingManager = [[DTXPollingManager alloc] initWithInterval:self->_currentProfilingConfiguration.samplingInterval];
			}
			
			if(needsPerformancePolling)
			{
				[self->_pollingManager addPollable:[[DTXPerformanceSampler alloc] initWithConfiguration:self->_currentProfilingConfiguration] handler:^(DTXPerformanceSampler* pollable) {
					[weakSelf performanceSamplerDidPoll:pollable];
				}];
			}
			
			if(needsRNPolling)
			{
				DTXReactNativeSampler* rnSampler = [[DTXReactNativeSampler alloc] initWithConfiguration:self->_currentProfilingConfiguration];
				if(rnSampler != nil)
				{
					[self->_pollingManager addPollable:rnSampler handler:^(DTXReactNativeSampler* pollable) {
						[weakSelf reactNativeSamplerDidPoll:pollable];
					}];
				}
			}
			
			__DTXProfilerAddActiveProfiler(self);
			
			[self->_pollingManager resume];
			
			dtx_log_info(@"Started profiling");
		} qos:QOS_CLASS_USER_INTERACTIVE];
	}];
}

- (void)_symbolicateRemainingStackTracesInternal
{
	NSPredicate* unsymbolicated = [NSPredicate predicateWithFormat:@"stackTraceIsSymbolicated == NO"];
	NSFetchRequest* fr = [DTXPerformanceSample fetchRequest];
	fr.predicate = unsymbolicated;
	
	NSArray<DTXPerformanceSample*>* unsymbolicatedSamples = [_backgroundContext executeFetchRequest:fr error:NULL];
	[unsymbolicatedSamples enumerateObjectsUsingBlock:^(DTXPerformanceSample * _Nonnull unsymbolicatedSample, NSUInteger idx, BOOL * _Nonnull stop) {
		[self _symbolicatePerformanceSample:unsymbolicatedSample];
	}];
}

- (void)_symbolicatePerformanceSample:(DTXPerformanceSample *)unsymbolicatedSample
{
	NSMutableArray* symbolicatedStackTrace = [NSMutableArray new];
	
	[unsymbolicatedSample.heaviestStackTrace enumerateObjectsUsingBlock:^(NSNumber* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXAddressInfo* addressInfo = [[DTXAddressInfo alloc] initWithAddress:obj.unsignedIntegerValue];
		[symbolicatedStackTrace addObject:[addressInfo dictionaryRepresentation]];
	}];
	
	unsymbolicatedSample.heaviestStackTrace = symbolicatedStackTrace;
	unsymbolicatedSample.stackTraceIsSymbolicated = YES;
}

- (void)_symbolicateRemainingJavaScriptStackTracesInternal
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

- (void)_addMarkerPerformanceSampleAtTimestamp:(NSDate*)timestamp
{
	__kindof DTXPerformanceSample* perfSample;
	
	if(self->_currentProfilingConfiguration.recordThreadInformation)
	{
		perfSample = [[DTXPerformanceSample alloc] initWithContext:self->_backgroundContext];
	}
	else
	{
		perfSample = [[DTXPerformanceSample alloc] initWithContext:self->_backgroundContext];
	}
	
	perfSample.timestamp = timestamp;
	perfSample.hidden = YES;
	
	[self->_profilerStoryListener addPerformanceSample:perfSample];
	
	[_pendingSamples addObject:perfSample];
	[self _flushPendingSamplesInternal];
}

- (void)stopProfilingWithCompletionHandler:(void(^ __nullable)(NSError* __nullable error))handler
{
	DTX_ASSERT_RECORDING
	
	dtx_log_info(@"Stopping profiling");
	
	[_pollingManager suspend];
	_pollingManager = nil;
	
	__DTXProfilerRemoveActiveProfiler(self);
	
	[self _flushPendingSamplesWithInternalCompletionHandler:^{
		self->_currentRecording.endTimestamp = [NSDate date];
		
		[self->_profilerStoryListener updateRecording:self->_currentRecording stopRecording:YES];
		
		if(self->_currentProfilingConfiguration.collectStackTraces == YES
		   && self->_currentProfilingConfiguration.symbolicateStackTraces == YES)
		{
			[self _symbolicateRemainingStackTracesInternal];
		}
		
//		if(self->_currentRecording.hasReactNative
//		   && self->_currentProfilingConfiguration.profileReactNative == YES
//		   && self->_currentProfilingConfiguration.collectJavaScriptStackTraces == YES
//		   && self->_currentProfilingConfiguration.symbolicateJavaScriptStackTraces == YES)
//		{
//			[self _symbolicateRemainingJavaScriptStackTracesInternal];
//		}
		
		NSError* err;
		
#if DEBUG
		if(self._cleanForDemo)
		{
			NSFetchRequest* fr = DTXNetworkSample.fetchRequest;
			fr.predicate = [NSPredicate predicateWithFormat:@"responseTimestamp == nil"];
			NSBatchDeleteRequest* bd = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fr];
			NSError* error;
			[self->_backgroundContext executeRequest:bd error:&error];
			
			fr = DTXActivitySample.fetchRequest;
			fr.predicate = [NSPredicate predicateWithFormat:@"endTimestamp == nil"];
			bd = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fr];
			[self->_backgroundContext executeRequest:bd error:&error];
		}
#endif
		
		[self->_backgroundContext save:&err];
		
		[self _closeContainerInternal];
		
		self->_container = nil;
		
		self.recording = NO;
		
		dtx_log_info(@"Stopped profiling");
		
		if(handler != nil)
		{
			handler(err);
		}
		
		self->_currentProfilingConfiguration = nil;
	}];
}

- (void)_addTag:(NSString*)_tag timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXTag* tag = [[DTXTag alloc] initWithContext:self->_backgroundContext];
		tag.timestamp = timestamp;
		tag.name = _tag;
		
		[self->_profilerStoryListener addTagSample:tag];
		
		[self _addPendingSampleInternal:tag];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_addLogLine:(NSString *)line timestamp:(NSDate*)timestamp
{
	[self _addLogLine:line objects:nil timestamp:timestamp];
}

- (void)_addLogLine:(NSString *)line objects:(NSArray *)objects timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	[self->_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXLogSample* log = [[DTXLogSample alloc] initWithContext:self->_backgroundContext];
		log.timestamp = timestamp;
		log.line = line;
		log.objects = objects;
		[self->_profilerStoryListener addLogSample:log];
		[self _addPendingSampleInternal:log];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo eventType:(_DTXEventType)eventType stackTrace:(NSArray*)stackTrace threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_DTXShouldIgnoreEvent(eventType, category, self.profilingConfiguration) == YES)
	{
		return;
	}
	
	[self->_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		Class signpostSampleClass = _DTXClassForEventType(eventType);
		
		DTXSignpostSample* signpostSample = [[signpostSampleClass alloc] initWithContext:self->_backgroundContext];
		signpostSample.timestamp = timestamp;
		signpostSample.uniqueIdentifier = identifier;
		signpostSample.category = category;
		signpostSample.categoryHash = category.sufficientHash;
		signpostSample.name = name;
		signpostSample.nameHash = name.sufficientHash;
		signpostSample.additionalInfoStart = additionalInfo;
		signpostSample.isTimer = eventType == _DTXEventTypeJSTimer;
		signpostSample.stackTrace = stackTrace;
		signpostSample.stackTraceIsSymbolicated = NO;
		signpostSample.startThreadNumber = [self _threadForThreadIdentifier:threadIdentifier].number;
		
		[self->_profilerStoryListener markEventIntervalBegin:signpostSample];
		
		self->_pendingSignpostSamples[identifier] = signpostSample;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(nullable NSString*)additionalInfo threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	[self->_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXSignpostSample* signpostSample = self->_pendingSignpostSamples[identifier];
		if(signpostSample == nil)
		{
			return;
		}
		[self->_pendingSignpostSamples removeObjectForKey:identifier];

		signpostSample.endTimestamp = timestamp;
		signpostSample.duration = [signpostSample.endTimestamp timeIntervalSinceDate:signpostSample.timestamp];
		signpostSample.eventStatus = eventStatus;
		signpostSample.additionalInfoEnd = additionalInfo;
		signpostSample.endThreadNumber = [self _threadForThreadIdentifier:threadIdentifier].number;
		
		[self->_profilerStoryListener markEventIntervalEnd:signpostSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_markEventWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo eventType:(_DTXEventType)eventType threadIdentifier:(uint64_t)threadIdentifier timestamp:(NSDate*)timestamp
{
	if(_DTXShouldIgnoreEvent(eventType, category, self.profilingConfiguration) == YES)
	{
		return;
	}
	
	DTX_IGNORE_NOT_RECORDING
	[self->_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		Class signpostSampleClass = _DTXClassForEventType(eventType);
		
		DTXSignpostSample* signpostSample = [[signpostSampleClass alloc] initWithContext:self->_backgroundContext];
		signpostSample.timestamp = timestamp;
		signpostSample.uniqueIdentifier = identifier;
		signpostSample.category = category;
		signpostSample.categoryHash = category.sufficientHash;
		signpostSample.name = name;
		signpostSample.nameHash = name.sufficientHash;
		signpostSample.additionalInfoStart = additionalInfo;
		signpostSample.eventStatus = eventStatus;
		signpostSample.endTimestamp = signpostSample.timestamp;
		signpostSample.isEvent = YES;
		signpostSample.startThreadNumber = [self _threadForThreadIdentifier:threadIdentifier].number;
		signpostSample.endThreadNumber = [self _threadForThreadIdentifier:threadIdentifier].number;
		
		[self->_profilerStoryListener markEvent:signpostSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_flushPendingSamplesInternal
{
	[_backgroundContext save:NULL];
	
	for (DTXSample* obj in _pendingSamples) {
		[self->_backgroundContext refreshObject:obj mergeChanges:NO];
	}
	
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
//
//	NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:[_currentRecording dictionaryRepresentationForPropertyList] format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
//	NSURL* plistURL = [_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.plist"];
//	[plistData writeToURL:plistURL atomically:YES];
	
	[_container.persistentStoreCoordinator.persistentStores.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[self->_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
//	DTXWriteZipFileWithDirectoryURL([_currentProfilingConfiguration.recordingFileURL URLByAppendingPathExtension:@"zip"], _currentProfilingConfiguration.recordingFileURL);
}

- (DTXThreadInfo*)_threadForThreadIdentifier:(uint64_t)identifier
{
	DTXThreadInfo* threadInfo = self->_threads[@(identifier)];
	if(threadInfo == nil)
	{
		threadInfo = [[DTXThreadInfo alloc] initWithContext:self->_backgroundContext];
		threadInfo.number = self->_threads.count;
		self->_threads[@(identifier)] = threadInfo;
		threadInfo.recording = self->_currentRecording;
	}
	return threadInfo;
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
	
	NSDate* timestamp = NSDate.date;
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		__kindof DTXPerformanceSample* perfSample = [[DTXPerformanceSample alloc] initWithContext:self->_backgroundContext];
		
		perfSample.timestamp = timestamp;
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
			for (DTXThreadMeasurement* obj in cpu.threads) {
				DTXThreadInfo* threadInfo = [self _threadForThreadIdentifier:obj.identifier];
				threadInfo.name = obj.name;
				
				[self->_profilerStoryListener createdOrUpdatedThreadInfo:threadInfo];
				
				DTXThreadPerformanceSample* threadSample = [[DTXThreadPerformanceSample alloc] initWithContext:self->_backgroundContext];
				threadSample.cpuUsage = obj.cpu;
				threadSample.threadInfo = threadInfo;
				
				[perfSample addThreadSamplesObject:threadSample];
			}
			
			if(self->_currentProfilingConfiguration.collectStackTraces)
			{
				[perfSample setHeaviestThreadIdx:@(cpu.heaviestThreadIdx)];
				if(perfSample.threadSamples.count > 0)
				{
					[perfSample setHeaviestThread:@(perfSample.threadSamples[cpu.heaviestThreadIdx].threadInfo.number)];
				}
				[perfSample setHeaviestStackTrace:stackTrace];
				[perfSample setStackTraceIsSymbolicated:NO];
			}
		}
		
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
	
	NSDate* timestamp = NSDate.date;
	
	[_backgroundContext performBlockAndWait:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXReactNativePeroformanceSample* rnPerfSample = [[DTXReactNativePeroformanceSample alloc] initWithContext:self->_backgroundContext];
		rnPerfSample.timestamp = timestamp;
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
		
		[self->_profilerStoryListener addRNPerformanceSample:rnPerfSample];
		
		[self _addPendingSampleInternal:rnPerfSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_addPendingSampleInternal:(DTXSample*)pendingSample
{
	if(_awaitsMarkerInsertion)
	{
		[self _addMarkerPerformanceSampleAtTimestamp:[pendingSample.timestamp dateByAddingTimeInterval:-0.0001]];
		_awaitsMarkerInsertion = NO;
	}
	
	[_pendingSamples addObject:pendingSample];
	
	if(_pendingSamples.count >= _currentProfilingConfiguration.numberOfSamplesBeforeFlushToDisk)
	{
		[self _flushPendingSamplesInternal];
	}
}

- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request cookieHeaders:(NSDictionary<NSString*, NSString*>*)cookieHeaders userAgent:(NSString*)userAgent uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_currentProfilingConfiguration.recordNetwork == NO)
	{
		return;
	}
	
	if(_currentProfilingConfiguration.recordLocalhostNetwork == NO && ([request.URL.host isEqualToString:@"localhost"] || [request.URL.host isEqualToString:@"127.0.0.1"]))
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXNetworkSample* networkSample = [[DTXNetworkSample alloc] initWithContext:self->_backgroundContext];
		networkSample.timestamp = timestamp;
		networkSample.uniqueIdentifier = uniqueIdentifier;
		networkSample.url = request.URL.absoluteString;
		networkSample.requestTimeoutInterval = request.timeoutInterval;
		networkSample.requestHTTPMethod = request.HTTPMethod;
		
		NSMutableDictionary* requestHeaders = request.allHTTPHeaderFields.mutableCopy ?: [NSMutableDictionary new];
		if(cookieHeaders != nil && requestHeaders[@"Cookie"] == nil)
		{
			[requestHeaders addEntriesFromDictionary:cookieHeaders];
		}
		if(userAgent != nil && requestHeaders[@"User-Agent"] == nil)
		{
			[requestHeaders setObject:userAgent forKey:@"User-Agent"];
		}
		networkSample.requestHeaders = requestHeaders;
		networkSample.requestHeadersFlat = requestHeaders.debugDescription;
		
		if(request.HTTPBody.length > 0)
		{
			DTXNetworkData* requestData = [[DTXNetworkData alloc] initWithContext:self->_backgroundContext];
			requestData.data = request.HTTPBody;
			networkSample.requestData = requestData;
		}
		networkSample.requestDataLength = request.HTTPBody.length + request.allHTTPHeaderFields.description.length;
		
		[self->_profilerStoryListener startRequestWithNetworkSample:networkSample];
		
		self->_pendingNetworkSamples[networkSample.uniqueIdentifier] = networkSample;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_currentProfilingConfiguration.recordNetwork == NO)
	{
		return;
	}
	
	if(_currentProfilingConfiguration.recordLocalhostNetwork == NO && ([response.URL.host isEqualToString:@"localhost"] || [response.URL.host isEqualToString:@"127.0.0.1"]))
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXNetworkSample* networkSample = self->_pendingNetworkSamples[uniqueIdentifier];
		if(networkSample == nil)
		{
			return;
		}
		[self->_pendingNetworkSamples removeObjectForKey:uniqueIdentifier];
		
		networkSample.responseTimestamp = timestamp;
		networkSample.duration = [timestamp timeIntervalSinceDate:networkSample.timestamp];
		
		networkSample.responseSuggestedFilename = response.suggestedFilename;
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

- (void)_addRNDataFromFunction:(NSString*)function arguments:(NSArray<NSString*>*)arguments returnValue:(NSString*)rv exception:(NSString*)exception isFromNative:(BOOL)isFromNative timestamp:(NSDate*)timestamp;
{
	DTX_IGNORE_NOT_RECORDING
	
	if(_currentProfilingConfiguration.recordReactNativeBridgeData == NO)
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXReactNativeDataSample* rnDataSample = [[DTXReactNativeDataSample alloc] initWithContext:self->_backgroundContext];
		rnDataSample.timestamp = timestamp;
		rnDataSample.isFromNative = isFromNative;
		rnDataSample.function = function;
		
		DTXReactNativeBridgeData* bridgeData = [[DTXReactNativeBridgeData alloc] initWithContext:self->_backgroundContext];
		bridgeData.arguments = arguments;
		bridgeData.returnValue = rv;
		bridgeData.exception = exception;
		
		rnDataSample.data = bridgeData;
		
		[self->_profilerStoryListener addRNBridgeDataSample:rnDataSample];
		
		[self _addPendingSampleInternal:rnDataSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

@end
