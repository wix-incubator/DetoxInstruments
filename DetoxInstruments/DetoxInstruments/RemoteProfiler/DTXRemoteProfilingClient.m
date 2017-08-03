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

@interface DTXRemoteProfilingClient () <DTXProfilerStoryDecoder>
{
	DTXRecording* _recording;
	DTXSampleGroup* _currentSampleGroup;
	NSMutableDictionary<NSNumber*, DTXThreadInfo*>* _threads;
}

@end

@implementation DTXRemoteProfilingClient

- (instancetype)initWithProfilingTarget:(DTXRemoteProfilingTarget*)target managedObjectContext:(NSManagedObjectContext*)ctx
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
	}
	
	return self;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration*)configuration
{
	_threads = [NSMutableDictionary new];
	[_target startProfilingWithConfiguration:configuration];
}

- (void)stopWithCompletionHandler:(void (^)(void))completionHandler
{
	
}

- (void)_addSample:(NSDictionary*)sampleDict entityDescription:(NSEntityDescription *)entityDescription
{
	Class cls = NSClassFromString(entityDescription.managedObjectClassName);
	__kindof DTXSample* sample = [[cls alloc] initWithPropertyListDictionaryRepresentation:sampleDict context:_managedObjectContext];
	
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

#pragma mark DTXProfilerStoryDecoder

- (void)willDecodeStoryEvent {}

- (void)didDecodeStoryEvent
{
	[self.delegate remoteProfilingClientDidChangeDatabase:self];
}

- (void)addLogSample:(NSDictionary *)logSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:logSample entityDescription:entityDescription];
}

- (void)addPerformanceSample:(NSDictionary *)perfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:perfrmanceSample entityDescription:entityDescription];
}

- (void)addRNPerformanceSample:(NSDictionary *)rnPerfrmanceSample entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:rnPerfrmanceSample entityDescription:entityDescription];
}

- (void)addTag:(NSDictionary *)tag entityDescription:(NSEntityDescription *)entityDescription
{
	[self _addSample:tag entityDescription:entityDescription];
}

- (void)createRecording:(NSDictionary *)recording entityDescription:(NSEntityDescription *)entityDescription
{
	DTXRecording* recordingObj = [[DTXRecording alloc] initWithPropertyListDictionaryRepresentation:recording context:_managedObjectContext];
	recordingObj.dtx_profilingConfiguration.recordingFileURL = [NSURL fileURLWithPath:recording[@"profilingConfiguration"][@"recordingFileName"]];
	
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

@end
