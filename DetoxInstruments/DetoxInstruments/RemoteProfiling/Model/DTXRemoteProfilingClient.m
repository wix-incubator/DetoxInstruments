//
//  DTXRemoteProfilingClient.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 26/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRemoteProfilingClient.h"
#import "DTXProfilingBasics.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import <DTXSourceMaps/DTXSourceMaps.h>
#import <pthread.h>

#import "DTXLogging.h"
DTX_CREATE_LOG(RemoteProfilingClient)

#define SET_RECORDING SET_VALUE(_isRecording,YES)
#define SET_NOT_RECORDING SET_VALUE(_isRecording,NO)
#define REQUIRE_RECORDING REQUIRE_VALUE(_isRecording,YES)

#define SET_ACCEPTING SET_VALUE(_isAcceptingOpportunisticSamples,YES)
#define SET_NOT_ACCEPTING SET_VALUE(_isAcceptingOpportunisticSamples,NO)
#define REQUIRE_ACCEPTING REQUIRE_VALUE(_isAcceptingOpportunisticSamples,YES)

#define SET_VALUE(ARG, VAL) \
pthread_mutex_lock(&ARG##Mutex); \
ARG = VAL; \
pthread_mutex_unlock(&ARG##Mutex);

#define REQUIRE_VALUE(ARG, VAL) {\
pthread_mutex_lock(&ARG##Mutex); \
BOOL ___##ARG = ARG; \
pthread_mutex_unlock(&ARG##Mutex); \
if(___##ARG != VAL) { /*NSLog(@"🤷‍♂️ Ignoring");*/ \
return; }\
}

@interface DTXRemoteProfilingClient () <DTXRemoteTargetDelegate>
{
	BOOL _isLocal;
	
	pthread_mutex_t _isRecordingMutex;
	BOOL _isRecording;
	
	pthread_mutex_t _isAcceptingOpportunisticSamplesMutex;
	BOOL _isAcceptingOpportunisticSamples;
	
	DTXRecording* _recording;
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
	
	pthread_mutex_t _opportunisticSourceMutex;
	NSMutableDictionary<NSString*, NSMutableDictionary*>* _opportunisticSamples;
	NSMutableDictionary<NSString*, NSDictionary*>* _opportunisticUpdates;
	dispatch_queue_t _opportunisticQueue;
	dispatch_source_t _opportunisticSource;
}

@end

@implementation DTXRemoteProfilingClient

- (instancetype)initWithProfilingTargetForLocalRecording:(DTXRemoteTarget*)target
{
	NSParameterAssert(target != nil);
	
	self = [super init];
	
	if(self)
	{
		_target = target;
		_target.delegate = self;
		
		_isLocal = YES;
	}
	
	return self;
}

- (instancetype)initWithProfilingTarget:(DTXRemoteTarget*)target managedObjectContext:(NSManagedObjectContext*)ctx
{
	NSParameterAssert(ctx != nil);
	NSParameterAssert(target != nil);
	
	self = [super init];
	
	if(self)
	{
		_target = target;
		_target.delegate = self;
		_managedObjectContext = ctx;
		
		_target.managedObjectContext = ctx;
		_target.storyDecoder = self;
		
		pthread_mutex_init(&_opportunisticSourceMutex, NULL);
		pthread_mutex_init(&_isRecordingMutex, NULL);
		
		_opportunisticSamples = [NSMutableDictionary new];
		_opportunisticUpdates = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)_resetOpportunisticSamplesTimerIfNeeded
{
	pthread_mutex_lock_deferred_unlock(&_opportunisticSourceMutex);
	if(_opportunisticQueue == nil)
	{
		return;
	}
	
	if(_opportunisticSource != nil)
	{
		return;
	}
	
	_opportunisticSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _opportunisticQueue);
	uint64_t interval = 0.75 * NSEC_PER_SEC;
	dispatch_source_set_timer(_opportunisticSource, dispatch_time(DISPATCH_TIME_NOW, interval), interval, interval);
	dispatch_source_set_event_handler(_opportunisticSource, ^{
		pthread_mutex_lock(&_opportunisticSourceMutex);
		if(_opportunisticSource)
		{
			dispatch_source_cancel(_opportunisticSource);
			_opportunisticSource = nil;
		}
		pthread_mutex_unlock(&_opportunisticSourceMutex);
		
		[self _flushPendingOpportunisticSamplesAndUpdates];
	});
	
	dispatch_resume(_opportunisticSource);
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration
{
	SET_RECORDING
	SET_ACCEPTING
	
	if(_isLocal == NO)
	{
		dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
		_opportunisticQueue = dispatch_queue_create("com.wix.DTXRemoteProfilingOpportunisticSamples", dispatch_queue_attr_make_with_autorelease_frequency(qosAttribute, DISPATCH_AUTORELEASE_FREQUENCY_WORK_ITEM));
	}
	
	_threads = [NSMutableDictionary new];
	[_target startProfilingWithConfiguration:configuration local:_isLocal];
}

- (void)stopProfiling
{
	SET_NOT_ACCEPTING
	SET_NOT_RECORDING
	
	[_target stopProfiling];
	
//	if(_isLocal == NO)
//	{
//		[self.delegate remoteProfilingClient:self didStopRecordingWithZippedRecordingData:nil];
//	}
}

- (void)_addOpportunisticSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	REQUIRE_ACCEPTING
	
	NSMutableDictionary* mutableSample = sampleDict.mutableCopy;
	
	_opportunisticSamples[mutableSample[@"sampleIdentifier"]] = mutableSample;
	
	[self _resetOpportunisticSamplesTimerIfNeeded];
}

- (void)_addOpportunisticUpdate:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	REQUIRE_ACCEPTING
	
	_opportunisticUpdates[sampleDict[@"sampleIdentifier"]] = sampleDict;
	
	[self _resetOpportunisticSamplesTimerIfNeeded];
}

- (void)_flushPendingOpportunisticSamplesAndUpdatesInternal
{
	for(NSString* sampleIdentifier in _opportunisticSamples)
	{
		NSMutableDictionary* sample = _opportunisticSamples[sampleIdentifier];
		NSEntityDescription* entityDescription = [NSClassFromString(sample[@"__dtx_className"]) entity];
		
		[self _addSample:sample entityDescription:entityDescription saveContext:NO];
	}
	
	[_opportunisticSamples removeAllObjects];
	
	NSArray* allUpdates = _opportunisticUpdates.allKeys;
	
	NSFetchRequest* fr = [DTXSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"sampleIdentifier in %@", allUpdates];
	NSArray* samples = [_managedObjectContext executeFetchRequest:fr error:NULL];
	
	for(DTXSample* sample in samples)
	{
		NSDictionary* update = _opportunisticUpdates[sample.sampleIdentifier];
		[sample updateWithPropertyListDictionaryRepresentation:update];
	}
	
	[_opportunisticUpdates removeAllObjects];
}

- (void)_flushPendingOpportunisticSamplesAndUpdatesNow
{
	[_managedObjectContext performBlockAndWait:^{
		[self _flushPendingOpportunisticSamplesAndUpdatesInternal];
	}];
}

- (void)_flushPendingOpportunisticSamplesAndUpdates
{
	[_managedObjectContext performBlock:^{
		[self _flushPendingOpportunisticSamplesAndUpdatesInternal];
	}];
}

- (void)_addSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription saveContext:(BOOL)saveContext
{
	[self _addSample:sampleDict entityDescription:entityDescription defaultEntityDescription:nil saveContext:saveContext];
}

- (void)_addSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription defaultEntityDescription:(NSEntityDescription *)defaultEntityDescription saveContext:(BOOL)saveContext
{
	REQUIRE_RECORDING
	
	if(entityDescription == nil && defaultEntityDescription != nil)
	{
		entityDescription = defaultEntityDescription;
	}
	
	if(entityDescription == nil)
	{
		return;
	}
	
	Class cls = NSClassFromString(entityDescription.managedObjectClassName);
	__kindof DTXSample* sample = [[cls alloc] initWithPropertyListDictionaryRepresentation:sampleDict context:_managedObjectContext];
	
	if([sample isKindOfClass:[DTXReactNativePeroformanceSample class]] && _delegate.sourceMapsParser)
	{
		DTXReactNativePeroformanceSample* rnSample = (id)sample;
		
		if(rnSample.stackTraceIsSymbolicated == NO && NO/*_recording.dtx_profilingConfiguration.symbolicateJavaScriptStackTraces*/)
		{
			BOOL wasSymbolicated = NO;
			rnSample.stackTrace = DTXRNSymbolicateJSCBacktrace(_delegate.sourceMapsParser, rnSample.stackTrace, &wasSymbolicated);
			rnSample.stackTraceIsSymbolicated = wasSymbolicated;
		}
	}
	
	if(saveContext)
	{
		[self _saveContext];
	}
}

- (void)_saveContext
{
	NSError* err;
	if([_managedObjectContext save:&err] == NO)
	{
		dtx_log_error(@"Error saving context: %@", err);
	}
	
	if(_recording.managedObjectContext.insertedObjects > 0)
	{
		[self.delegate remoteProfilingClientDidChangeDatabase:self];
	}
}

- (DTXThreadInfo*)_threadWithNumber:(NSNumber*)threadNumber
{
	DTXThreadInfo* thread = _threads[threadNumber];
	
	if(thread == nil)
	{
		//Do not need to set propertiess here,they will updated later.
		thread = [[DTXThreadInfo alloc] initWithContext:_managedObjectContext];
		_threads[threadNumber] = thread;
	}
	
	return thread;
}

#pragma mark DTXRemoteTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteTarget *)target
{
	_target = nil;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate remoteProfilingClient:self didStopRecordingWithZippedRecordingData:nil];
	});
}

- (void)profilingTarget:(DTXRemoteTarget*)target didFinishLaunchProfilingWithZippedData:(NSData*)zippedData
{
	if(_isLocal == NO)
	{
		pthread_mutex_lock(&_opportunisticSourceMutex);
		if(_opportunisticSource != nil)
		{
			dispatch_cancel(_opportunisticSource);
			
			[self _flushPendingOpportunisticSamplesAndUpdatesNow];
		}
		_opportunisticQueue = nil;
		pthread_mutex_unlock(&_opportunisticSourceMutex);
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate remoteProfilingClient:self didStopRecordingWithZippedRecordingData:zippedData];
	});
}

#pragma mark DTXProfilerStoryDecoder

- (void)willDecodeStoryEvent {}

- (void)didDecodeStoryEvent {}

- (void)setSourceMapsData:(NSDictionary*)sourceMapsData;
{
	[self.delegate remoteProfilingClient:self didReceiveSourceMapsData:sourceMapsData[@"data"]];
}

- (void)addLogSample:(NSDictionary *)logSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:logSample entityDescription:entityDescription saveContext:YES];
}

- (void)addPerformanceSample:(NSDictionary *)performanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:performanceSample entityDescription:entityDescription defaultEntityDescription:DTXPerformanceSample.entity saveContext:YES];
}

- (void)addRNPerformanceSample:(NSDictionary *)rnPerfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:rnPerfrmanceSample entityDescription:entityDescription saveContext:YES];
}

- (void)addTagSample:(NSDictionary *)tag entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:tag entityDescription:entityDescription saveContext:YES];
}

- (void)createRecording:(NSDictionary *)recording entityDescription:(NSEntityDescription *)entityDescription
{
	DTXRecording* recordingObj = [[DTXRecording alloc] initWithPropertyListDictionaryRepresentation:recording context:_managedObjectContext];
	[recordingObj.dtx_profilingConfiguration setValue:[NSURL fileURLWithPath:recording[@"profilingConfiguration"][@"recordingFileName"]] forKey:@"_nonkvc_recordingFileURL"];
	
	NSAssert(_recording == nil, @"A recording already exists");
	_recording = recordingObj;
	
	//Save parent context here so it propagates to the view context and the recording is discovered on the view thread.
	[self _saveContext];
	
	[self.delegate remoteProfilingClient:self didCreateRecording:_recording];
}

- (void)createdOrUpdatedThreadInfo:(NSDictionary *)threadInfo entityDescription:(NSEntityDescription *)entityDescription
{
	DTXThreadInfo* thread = [self _threadWithNumber:threadInfo[@"number"]];
	thread.recording = _recording;
	
	[thread updateWithPropertyListDictionaryRepresentation:threadInfo];
}

- (void)finishWithResponseForNetworkSample:(NSDictionary *)networkSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addOpportunisticUpdate:networkSample entityDescription:entityDescription];
}

- (void)addRNBridgeDataSample:(NSDictionary*)rbBridgeDataSample entityDescription:(NSEntityDescription*)entityDescription
{
	[self _addSample:rbBridgeDataSample entityDescription:entityDescription saveContext:YES];
}

- (void)startRequestWithNetworkSample:(NSDictionary *)networkSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addOpportunisticSample:networkSample entityDescription:entityDescription];
}

- (void)updateRecording:(NSDictionary *)recording stopRecording:(NSNumber *)stopRecording entityDescription:(NSEntityDescription *)entityDescription
{
	[_recording updateWithPropertyListDictionaryRepresentation:recording];
	
	if(stopRecording.boolValue)
	{
		//We already notified the delegate, just perform last save.
		[self _saveContext];
	}
}

- (void)markEvent:(NSDictionary *)signpostSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addOpportunisticSample:signpostSample entityDescription:entityDescription];
}

- (void)markEventIntervalBegin:(NSDictionary *)signpostSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addOpportunisticSample:signpostSample entityDescription:entityDescription];
}

- (void)markEventIntervalEnd:(NSDictionary *)signpostSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addOpportunisticUpdate:signpostSample entityDescription:entityDescription];
}

- (void)performBlock:(void (^)(void))block
{
	[_managedObjectContext performBlock:block];
}

- (void)performBlockAndWait:(void (^)(void))block
{
	[_managedObjectContext performBlockAndWait:block];
}

@end
