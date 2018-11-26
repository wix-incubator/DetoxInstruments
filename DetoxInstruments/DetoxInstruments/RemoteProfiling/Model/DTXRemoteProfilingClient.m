//
//  DTXRemoteProfilingClient.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 26/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRemoteProfilingClient.h"
#import "DTXRemoteProfilingBasics.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import <DTXSourceMaps/DTXSourceMaps.h>
#import <pthread.h>

@interface DTXRemoteProfilingClient ()
{
	DTXRecording* _recording;
	DTXSampleGroup* _currentSampleGroup;
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
	
	dispatch_queue_t _aggregationCollectionQueue;
	dispatch_source_t _aggregationCollectionSource;
	
	pthread_mutex_t _opportunisticSourceMutext;
	NSMutableDictionary<NSString*, NSMutableDictionary*>* _opportunisticSamples;
	NSMutableDictionary<NSString*, NSDictionary*>* _opportunisticUpdates;
	dispatch_queue_t _opportunisticQueue;
	dispatch_source_t _opportunisticSource;
}

@end

@implementation DTXRemoteProfilingClient

- (instancetype)initWithProfilingTarget:(DTXRemoteTarget*)target managedObjectContext:(NSManagedObjectContext*)ctx
{
	NSParameterAssert(ctx != nil);
	NSParameterAssert(target != nil);
	
	self = [super init];
	
	if(self)
	{
		_target = target;
		_managedObjectContext = ctx;
		
		_target.managedObjectContext = ctx;
		_target.storyDecoder = self;
		
		dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_main(), 0);
		_aggregationCollectionQueue = dispatch_queue_create("com.wix.DTXRemoteProfilingAggregation", qosAttribute);
		
		_opportunisticQueue = dispatch_queue_create("com.wix.DTXRemoteProfilingOpportunisticSamples", qosAttribute);
		pthread_mutex_init(&_opportunisticSourceMutext, NULL);
		
		_opportunisticSamples = [NSMutableDictionary new];
		_opportunisticUpdates = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)_resetOpportunisticSamplesTimer
{
	pthread_mutex_lock(&_opportunisticSourceMutext);
	if(_opportunisticSource)
	{
		dispatch_source_cancel(_opportunisticSource);
		_opportunisticSource = nil;
	}
	
	_opportunisticSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _opportunisticQueue);
	uint64_t interval = 0.5 * NSEC_PER_SEC;
	dispatch_source_set_timer(_opportunisticSource, dispatch_time(DISPATCH_TIME_NOW, interval), interval, interval);
	dispatch_source_set_event_handler(_opportunisticSource, ^{
		pthread_mutex_lock(&_opportunisticSourceMutext);
		if(_opportunisticSource)
		{
			dispatch_source_cancel(_opportunisticSource);
			_opportunisticSource = nil;
		}
		pthread_mutex_unlock(&_opportunisticSourceMutext);
		
		[_managedObjectContext performBlockAndWait:^{
			for(NSString* sampleIdentifier in _opportunisticSamples)
			{
				NSMutableDictionary* sample = _opportunisticSamples[sampleIdentifier];
				NSEntityDescription* entityDescription = [NSClassFromString(sample[@"__dtx_className"]) entity];
				
				id parent = sample[@"parent"];
				sample[@"parent"] = nil;
				
				[self _addSample:sample entityDescription:entityDescription inParent:parent];
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
		}];
	});
	
	dispatch_resume(_opportunisticSource);
	pthread_mutex_unlock(&_opportunisticSourceMutext);
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration
{
	_threads = [NSMutableDictionary new];
	[_target startProfilingWithConfiguration:configuration];
	
	_aggregationCollectionSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _aggregationCollectionQueue);
	uint64_t interval = configuration.samplingInterval * NSEC_PER_SEC;
	dispatch_source_set_timer(_aggregationCollectionSource, dispatch_time(interval, 0), interval, interval);
	dispatch_source_set_event_handler(_aggregationCollectionSource, ^{
		[_managedObjectContext performBlockAndWait:^{
			@try
			{
				[_managedObjectContext save:NULL];
				
				if(_recording.managedObjectContext.insertedObjects > 0)
				{
					[self.delegate remoteProfilingClientDidChangeDatabase:self];
				}
			}
			@catch(NSException* ex) {}
		}];
	});
	
	dispatch_resume(_aggregationCollectionSource);
}

- (void)stopWithCompletionHandler:(void (^)(void))completionHandler
{
	dispatch_cancel(_aggregationCollectionSource);
	
	if(completionHandler)
	{
		completionHandler();
	}
}

- (void)_addSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription inParent:(DTXSampleGroup*)parent
{
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
	
	[self _addSampleObject:sample inParent:parent];
}

- (void)_addOpportunisticSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	NSMutableDictionary* mutableSample = sampleDict.mutableCopy;
	
	mutableSample[@"parent"] = _currentSampleGroup;
	_opportunisticSamples[mutableSample[@"sampleIdentifier"]] = mutableSample;
	
	[self _resetOpportunisticSamplesTimer];
}

- (void)_addOpportunisticUpdate:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	_opportunisticUpdates[sampleDict[@"sampleIdentifier"]] = sampleDict;
	
	[self _resetOpportunisticSamplesTimer];
}

- (void)_addSampleObject:(DTXSample*)sample inParent:(DTXSampleGroup*)parent
{
	if(parent == nil)
	{
		parent = _currentSampleGroup;
	}
	
	sample.parentGroup = parent;
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

#pragma mark DTXProfilerStoryDecoder

- (void)willDecodeStoryEvent {}

- (void)didDecodeStoryEvent {}

- (void)setSourceMapsData:(NSDictionary*)sourceMapsData;
{
	[self.delegate remoteProfilingClient:self didReceiveSourceMapsData:sourceMapsData[@"data"]];
}

- (void)addLogSample:(NSDictionary *)logSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:logSample entityDescription:entityDescription inParent:nil];
}

- (void)addPerformanceSample:(NSDictionary *)perfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:perfrmanceSample entityDescription:entityDescription inParent:nil];
}

- (void)addRNPerformanceSample:(NSDictionary *)rnPerfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:rnPerfrmanceSample entityDescription:entityDescription inParent:nil];
}

- (void)addTagSample:(NSDictionary *)tag entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:tag entityDescription:entityDescription inParent:nil];
}

- (void)createRecording:(NSDictionary *)recording entityDescription:(NSEntityDescription *)entityDescription
{
	DTXRecording* recordingObj = [[DTXRecording alloc] initWithPropertyListDictionaryRepresentation:recording context:_managedObjectContext];
	[recordingObj.dtx_profilingConfiguration setValue:[NSURL fileURLWithPath:recording[@"profilingConfiguration"][@"recordingFileName"]] forKey:@"_nonkvc_recordingFileURL"];
	
	NSAssert(_recording == nil, @"A recording already exists");
	_recording = recordingObj;
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
	[self _addSample:rbBridgeDataSample entityDescription:entityDescription inParent:nil];
}

- (void)popSampleGroup:(NSDictionary *)sampleGroup entityDescription:(NSEntityDescription *)entityDescription
{
	[_currentSampleGroup updateWithPropertyListDictionaryRepresentation:sampleGroup];
	NSAssert(_currentSampleGroup.parentGroup != nil, @"Cannot pop the root sample group");
	_currentSampleGroup = _currentSampleGroup.parentGroup;
}

- (void)pushSampleGroup:(NSDictionary *)sampleGroup isRootGroup:(NSNumber *)root entityDescription:(NSEntityDescription *)entityDescription
{
	DTXSampleGroup* sampleGroupObj = [[DTXSampleGroup alloc] initWithPropertyListDictionaryRepresentation:sampleGroup context:_managedObjectContext];
	
	if(root.boolValue)
	{
		_recording.rootSampleGroup = sampleGroupObj;
		
		//Save parent context here so it propagates to the view context and the recording is discovered on the view thread.
		[_managedObjectContext save:NULL];
		
		[self.delegate remoteProfilingClient:self didCreateRecording:_recording];
	}
	else
	{
		[self _addSampleObject:sampleGroupObj inParent:nil];
	}
	
	_currentSampleGroup = sampleGroupObj;
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
		[self.delegate remoteProfilingClientDidStopRecording:self];
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
