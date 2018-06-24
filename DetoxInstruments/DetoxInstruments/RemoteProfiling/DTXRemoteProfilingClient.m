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
#import "DTXRNJSCSourceMapsSupport.h"
#import <DTXSourceMaps/DTXSourceMaps.h>

@interface DTXRemoteProfilingClient ()
{
	DTXRecording* _recording;
	DTXSampleGroup* _currentSampleGroup;
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
	
	DTXSourceMapsParser* _sourceMapsParser;
	
	NSMutableArray<NSDictionary*>* _logSampleCache;
	dispatch_queue_t _logSampleCacheQueue;
	
	dispatch_source_t _logSampleCacheConsumerSource;
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
		
		_logSampleCacheQueue = dispatch_queue_create(NULL, 0);
		_logSampleCache = [NSMutableArray new];
	}
	
	return self;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration
{
	_threads = [NSMutableDictionary new];
	[_target startProfilingWithConfiguration:configuration];
	
	_logSampleCacheConsumerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _logSampleCacheQueue);
	
	uint64_t interval = configuration.samplingInterval * NSEC_PER_SEC;
	dispatch_source_set_timer(_logSampleCacheConsumerSource, dispatch_walltime(NULL, 0), interval, interval / 10);
	
	dispatch_source_set_event_handler(_logSampleCacheConsumerSource, ^{
		[_managedObjectContext performBlockAndWait:^{
			for (NSDictionary* entry in _logSampleCache) {
				NSDictionary* logSample = entry[@"sample"];
				NSEntityDescription* entityDescription = entry[@"description"];
				
				[self _addSample:logSample entityDescription:entityDescription];
			}
			
			if(_logSampleCache.count > 0)
			{
				[_managedObjectContext save:NULL];
			}
			
			[_logSampleCache removeAllObjects];
		}];
	});
	
	dispatch_resume(_logSampleCacheConsumerSource);
}

- (void)stopWithCompletionHandler:(void (^)(void))completionHandler
{
	dispatch_cancel(_logSampleCacheConsumerSource);
	
	if(completionHandler)
	{
		completionHandler();
	}
}

- (void)_addSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	Class cls = NSClassFromString(entityDescription.managedObjectClassName);
	__kindof DTXSample* sample = [[cls alloc] initWithPropertyListDictionaryRepresentation:sampleDict context:_managedObjectContext];
	
	if([sample isKindOfClass:[DTXReactNativePeroformanceSample class]] && _sourceMapsParser)
	{
		DTXReactNativePeroformanceSample* rnSample = (id)sample;
		
		if(rnSample.stackTraceIsSymbolicated == NO && _recording.dtx_profilingConfiguration.symbolicateJavaScriptStackTraces)
		{
			BOOL wasSymbolicated = NO;
			rnSample.stackTrace = DTXRNSymbolicateJSCBacktrace(_sourceMapsParser, rnSample.stackTrace, &wasSymbolicated);
			rnSample.stackTraceIsSymbolicated = wasSymbolicated;
		}
	}
	
	[self _addSampleObject:sample];
}

- (void)_addSampleObject:(DTXSample*)sample
{
	sample.parentGroup = _currentSampleGroup;
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

- (DTXNetworkSample*)_networkSampleWithIdentifier:(NSString*)sampleIdentifier
{
	NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
	fr.entity = [NSEntityDescription entityForName:@"NetworkSample" inManagedObjectContext:_managedObjectContext];
	fr.predicate = [NSPredicate predicateWithFormat:@"sampleIdentifier == %@", sampleIdentifier];
	NSArray* networkSamples = [_managedObjectContext executeFetchRequest:fr error:NULL];
	NSAssert(networkSamples.count <= 1, @"More than one network sample with identifier '%@' found", sampleIdentifier);
	
	return networkSamples.firstObject;
}

- (DTXSignpostSample*)_signpostSampleWithIdentifier:(NSString*)sampleIdentifier
{
	NSFetchRequest* fr = [DTXSignpostSample fetchRequest];
	fr.entity = [NSEntityDescription entityForName:@"SignpostSample" inManagedObjectContext:_managedObjectContext];
	fr.predicate = [NSPredicate predicateWithFormat:@"sampleIdentifier == %@", sampleIdentifier];
	NSArray* signpostSamples = [_managedObjectContext executeFetchRequest:fr error:NULL];
	NSAssert(signpostSamples.count <= 1, @"More than one signpost sample with identifier '%@' found", sampleIdentifier);
	
	return signpostSamples.firstObject;
}

#pragma mark DTXProfilerStoryDecoder

- (void)willDecodeStoryEvent {}

- (void)didDecodeStoryEvent
{
	if(_recording.managedObjectContext.insertedObjects > 0)
	{
		[self.delegate remoteProfilingClientDidChangeDatabase:self];
	}
	
	[_managedObjectContext save:NULL];
}

- (void)setSourceMapsData:(NSDictionary*)sourceMapsData;
{
	NSError* error;
	NSDictionary<NSString*, id>* sourceMaps = [NSJSONSerialization JSONObjectWithData:sourceMapsData[@"data"] options:0 error:&error];
	if(sourceMaps == nil)
	{
		NSLog(@"Error parsing source maps: %@", error);
		return;
	}
	
	_sourceMapsParser = [DTXSourceMapsParser sourceMapsParserForSourceMaps:sourceMaps];
}

- (void)addLogSample:(NSDictionary *)logSample entityDescription:(NSEntityDescription *)entityDescription
{
	dispatch_async(_logSampleCacheQueue, ^{
		[_logSampleCache addObject:@{@"sample": logSample, @"description": entityDescription}];
	});
	
//	[self _addSample:logSample entityDescription:entityDescription];
}

- (void)addPerformanceSample:(NSDictionary *)perfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:perfrmanceSample entityDescription:entityDescription];
}

- (void)addRNPerformanceSample:(NSDictionary *)rnPerfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:rnPerfrmanceSample entityDescription:entityDescription];
}

- (void)addTagSample:(NSDictionary *)tag entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:tag entityDescription:entityDescription];
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
	DTXNetworkSample* networkSampleObj = [self _networkSampleWithIdentifier:networkSample[@"sampleIdentifier"]];
	[networkSampleObj updateWithPropertyListDictionaryRepresentation:networkSample];
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
		
		[self.delegate remoteProfilingClient:self didCreateRecording:_recording];
	}
	else
	{
		[self _addSampleObject:sampleGroupObj];
	}
	
	_currentSampleGroup = sampleGroupObj;
}

- (void)startRequestWithNetworkSample:(NSDictionary *)networkSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:networkSample entityDescription:entityDescription];
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
	[self _addSample:signpostSample entityDescription:entityDescription];
}

- (void)markEventIntervalBegin:(NSDictionary *)signpostSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:signpostSample entityDescription:entityDescription];
}

- (void)markEventIntervalEnd:(NSDictionary *)signpostSample entityDescription:(NSEntityDescription *)entityDescription
{
	DTXSignpostSample* signpostSampleObj = [self _signpostSampleWithIdentifier:signpostSample[@"sampleIdentifier"]];
	[signpostSampleObj updateWithPropertyListDictionaryRepresentation:signpostSample];
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
