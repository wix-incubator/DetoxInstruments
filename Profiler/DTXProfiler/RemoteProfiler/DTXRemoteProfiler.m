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

@interface DTXProfiler ()

+ (NSManagedObjectModel*)_modelForProfiler;

@end

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
		
		DTXRNGetCurrentWorkingSourceMapsData(^(NSData* data) {
			if(data == nil)
			{
				return;
			}
			
			[self _serializeCommandWithSelector:NSSelectorFromString(@"setSourceMapsData:") entityName:@"" dict:@{@"data": data} additionalParams:nil];
		});
	}
	
	return self;
}

- (NSPersistentContainer*)_persistentStoreForProfilingDeleteExisting:(BOOL)deleteExisting
{
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[NSURL URLWithString:@""]];
	description.type = NSInMemoryStoreType;
	
	NSPersistentContainer* rv = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:self.class._modelForProfiler];
	rv.persistentStoreDescriptions = @[description];
	
	return rv;
}

- (void)_closeContainerInternal
{
	
}

- (void)_addPendingSampleInternal:(DTXSample*)pendingSample
{
	
}

- (void)_flushPendingSamplesInternal
{
	
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
	
	NSAssert(plistData != nil, @"Unable to encode data to property list.");
	
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
	
	[logSample.managedObjectContext deleteObject:logSample];
	[logSample.managedObjectContext save:NULL];
}

- (void)addPerformanceSample:(__kindof DTXPerformanceSample *)performanceSample
{
	if(self.profilingConfiguration.collectStackTraces && self.profilingConfiguration.symbolicateStackTraces && [performanceSample stackTraceIsSymbolicated] == NO)
	{
		[self _symbolicatePerformanceSample:performanceSample];
	}
	
	[self _serializeCommandWithSelector:_cmd managedObject:performanceSample additionalParams:nil];
	
	[performanceSample.managedObjectContext deleteObject:performanceSample];
	[performanceSample.managedObjectContext save:NULL];
}

- (void)addRNPerformanceSample:(DTXReactNativePeroformanceSample *)rnPerformanceSample
{
	//Instead of symbolicating here, send source maps data to Detox Instruments for remote symbolication.
	
	[self _serializeCommandWithSelector:_cmd managedObject:rnPerformanceSample additionalParams:nil];
	
	[rnPerformanceSample.managedObjectContext deleteObject:rnPerformanceSample];
	[rnPerformanceSample.managedObjectContext save:NULL];
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
	
	[networkSample.managedObjectContext deleteObject:networkSample];
	[networkSample.managedObjectContext save:NULL];
}

- (void)addRNBridgeDataSample:(DTXReactNativeDataSample*)rbBridgeDataSample;
{
	NSMutableDictionary* dict = [rbBridgeDataSample.dictionaryRepresentationOfChangedValuesForPropertyList mutableCopy];
	dict[@"sampleIdentifier"] = rbBridgeDataSample.sampleIdentifier;
	
	[self _serializeCommandWithSelector:_cmd entityName:rbBridgeDataSample.entity.name dict:dict additionalParams:nil];
	
	[rbBridgeDataSample.managedObjectContext deleteObject:rbBridgeDataSample];
	[rbBridgeDataSample.managedObjectContext save:NULL];
}

- (void)popSampleGroup:(DTXSampleGroup *)sampleGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:nil];
	
	[sampleGroup.managedObjectContext deleteObject:sampleGroup];
	[sampleGroup.managedObjectContext save:NULL];
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
	
	[tag.managedObjectContext deleteObject:tag];
	[tag.managedObjectContext save:NULL];
}

- (void)markEventIntervalBegin:(DTXSignpostSample *)signpostSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:signpostSample additionalParams:nil];
}

- (void)markEventIntervalEnd:(DTXSignpostSample *)signpostSample
{
	NSMutableDictionary* dict = [signpostSample.dictionaryRepresentationOfChangedValuesForPropertyList mutableCopy];
	dict[@"sampleIdentifier"] = signpostSample.sampleIdentifier;
	
	[self _serializeCommandWithSelector:_cmd entityName:signpostSample.entity.name dict:dict additionalParams:nil];
	
	[signpostSample.managedObjectContext deleteObject:signpostSample];
	[signpostSample.managedObjectContext save:NULL];
}

- (void)markEvent:(DTXSignpostSample *)signpostSample
{
	[self _serializeCommandWithSelector:_cmd managedObject:signpostSample additionalParams:nil];
	
	[signpostSample.managedObjectContext deleteObject:signpostSample];
	[signpostSample.managedObjectContext save:NULL];
}

@end

