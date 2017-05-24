//
//  DTXProfiler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfiler.h"
#import "DTXInstruments+CoreDataModel.h"
#import "NSManagedObject+Additions.h"
#import "DBPerformanceToolkit.h"
#import "DBBuildInfoProvider.h"
#import "DBURLProtocol.h"

#define DTX_ASSERT_RECORDING NSAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING NSAssert(self.recording == NO, @"A recording is already in progress");

@implementation DTXProfilingOptions

+ (instancetype)defaultProfilingOptions
{
	DTXProfilingOptions* rv = [DTXProfilingOptions new];;
	rv.recordNetwork = YES;
	rv.samplingInterval = 0.5;
	
	return rv;
}

@end

@interface DTXProfiler () <DBPerformanceToolkitDelegate, DBURLProtocolDelegate>

@property (assign, readwrite, getter=isRecording) BOOL recording;

@end

@implementation DTXProfiler
{
	DTXProfilingOptions* _currentProfilingOptions;
	
	DBPerformanceToolkit* _performanceToolkit;
	
	NSPersistentContainer* _container;
	NSManagedObjectContext* _backgroundContext;
	
	DTXRecording* _currentRecording;
	DTXSampleGroup* _rootSampleGroup;
	DTXSampleGroup* _currentSampleGroup;
	
	NSMutableArray<DTXSample*>* _pendingSamples;
}

+ (NSString *)_sanitizeFileNameString:(NSString *)fileName {
	NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
	return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

+ (NSURL*)_urlForNewRecording
{
	__block NSDateFormatter* dateFileFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFileFormatter = [NSDateFormatter new];
		dateFileFormatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
	});
	
	NSString* dateString = [dateFileFormatter stringFromDate:[NSDate date]];
	return [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"DetoxInstrumentsRecording_%@.sqlite", [self _sanitizeFileNameString:dateString]]];
}

- (void)startProfilingWithOptions:(DTXProfilingOptions *)options
{
	DTX_ASSERT_NOT_RECORDING
	
	self.recording = YES;
	
	_currentProfilingOptions = options;
	
	_pendingSamples = [NSMutableArray new];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[DTXProfiler _urlForNewRecording]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXProfiler class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		_backgroundContext = _container.newBackgroundContext;
		
		[_backgroundContext performBlockAndWait:^{
			DBBuildInfoProvider* buildProvider = [DBBuildInfoProvider new];
			NSProcessInfo* processInfo = [NSProcessInfo processInfo];
			UIDevice* currentDevice = [UIDevice currentDevice];
			
			_currentRecording = [[DTXRecording alloc] initWithContext:_backgroundContext];
			_currentRecording.appName = buildProvider.applicationName;
			_currentRecording.binaryName = processInfo.processName;
			_currentRecording.deviceName = currentDevice.name;
			_currentRecording.deviceOS = processInfo.operatingSystemVersionString;
			_currentRecording.deviceOSType = 0; //iOS
			_currentRecording.devicePhysicalMemory = processInfo.physicalMemory;
			_currentRecording.deviceProcessorCount = processInfo.processorCount;
			_currentRecording.deviceType = currentDevice.model;
			_currentRecording.processIdentifier = processInfo.processIdentifier;
			
			_rootSampleGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
			_rootSampleGroup.recording = _currentRecording;
			_currentSampleGroup = _rootSampleGroup;
			
			_performanceToolkit = [DBPerformanceToolkit new];
			_performanceToolkit.delegate = self;
			
			DBURLProtocol.delegate = self;
			[NSURLProtocol registerClass:[DBURLProtocol class]];
		}];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self stopProfiling];
		});

	}];
}

- (void)stopProfiling
{
	DTX_ASSERT_RECORDING
	
	[self _flushPendingSamplesWithInternalCompletionHandler:^{
		_currentRecording.endTimestamp = [NSDate date];
		
		[self _closeContainerInternal];
		
		[NSURLProtocol unregisterClass:[DBURLProtocol class]];
		
		_currentProfilingOptions = nil;
		
		self.recording = NO;
	}];
}

- (void)pushSampleGroupWithName:(NSString*)name
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING;
		
		NSLog(@"Pushing group");
		DTXSampleGroup* newGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
		newGroup.parentGroup = _currentSampleGroup;
		_currentSampleGroup = newGroup;
	}];
}

- (void)popSampleGroup
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING
		
		NSLog(@"Popping group");
		_currentSampleGroup.closeTimestamp = [NSDate date];
		_currentSampleGroup = _currentSampleGroup.parentGroup;
	}];
}

- (void)addTag:(NSString*)tag
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING
		
		DTXTag* tag = [[DTXTag alloc] initWithContext:_backgroundContext];
		tag.parentGroup = _currentSampleGroup;
		[self _addPendingSampleInternal:tag];
	}];
}

- (void)_flushPendingSamplesInternal
{
	NSLog(@"Flushing");
	
	[_backgroundContext save:NULL];
	[_pendingSamples enumerateObjectsUsingBlock:^(DTXSample * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_backgroundContext refreshObject:obj mergeChanges:YES];
	}];
	
	[_backgroundContext refreshObject:_currentSampleGroup mergeChanges:YES];
	
	[_pendingSamples removeAllObjects];
}

- (void)_flushPendingSamplesWithInternalCompletionHandler:(void(^)())completionHandler
{
	[_backgroundContext performBlock:^{
		[self _flushPendingSamplesInternal];
		
		if(completionHandler)
		{
			completionHandler();
		}
	}];
}

- (void)_closeContainerInternal
{
	NSLog(@"Closing");
	
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[_currentRecording dictionaryRepresentation] options:NSJSONWritingPrettyPrinted error:NULL];
	NSURL* url = [[[DTXProfiler _urlForNewRecording] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"output.json"];
	NSLog(@"%@", url);
	[jsonData writeToURL:url atomically:YES];
	
	[_container.persistentStoreCoordinator.persistentStores.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
	_container = nil;
}

#pragma mark DBPerformanceToolkitDelegate

- (void)performanceToolkitDidUpdateStats:(DBPerformanceToolkit *)performanceToolkit
{
	if(self.recording == NO)
	{
		return;
	}
	
	CGFloat cpu = performanceToolkit.currentCPU;
	CGFloat memory = performanceToolkit.currentMemory;
	CGFloat fps = performanceToolkit.currentFPS;
	
	[_backgroundContext performBlock:^{
		if(self.recording == NO)
		{
			return;
		}
		
		//		NSLog(@"Adding demo performance sample");
//		DTXAdvancedPerformanceSample* perfSample = [[DTXAdvancedPerformanceSample alloc] initWithContext:_backgroundContext];
		DTXPerformanceSample* perfSample = [[DTXPerformanceSample alloc] initWithContext:_backgroundContext];
		perfSample.cpuUsage = cpu;
		perfSample.memoryUsage = memory;
		perfSample.fps = fps;
		
//		for(uint8_t i = 0; i < 15; i++)
//		{
//			DTXThreadPerformanceSample* threadSample = [[DTXThreadPerformanceSample alloc] initWithContext:_backgroundContext];
//			threadSample.threadName = [NSString stringWithFormat:@"Thread %u", i];
//			threadSample.cpuUsage = 1.0 / 12;
//			threadSample.memoryUsage = 220 / 12;
//			
//			threadSample.advancedPerformanceSample = perfSample;
//		}
		
		perfSample.parentGroup = _currentSampleGroup;
		
		[self _addPendingSampleInternal:perfSample];
	}];
}

- (void)_addPendingSampleInternal:(DTXSample*)pendingSample
{
	[_pendingSamples addObject:pendingSample];
	
	if(_pendingSamples.count >= 120)
	{
		[self _flushPendingSamplesInternal];
	}
}

#pragma mark DBURLProtocolDelegate

- (void)urlProtocol:(DBURLProtocol*)protocol didStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier
{
	[_backgroundContext performBlock:^{
		DTXNetworkSample* networkSample = [[DTXNetworkSample alloc] initWithContext:_backgroundContext];
		networkSample.uniqueIdentifier = uniqueIdentifier;
		networkSample.url = request.URL.absoluteString;
		networkSample.requestTimeoutInterval = request.timeoutInterval;
		networkSample.requestHTTPMethod = request.HTTPMethod;
		networkSample.requestHeaders = request.allHTTPHeaderFields;
		
		DTXNetworkData* requestData = [[DTXNetworkData alloc] initWithContext:_backgroundContext];
		requestData.data = request.HTTPBody;
		networkSample.requestData = requestData;
		
		networkSample.parentGroup = _currentSampleGroup;
	}];
}

- (void)urlProtocol:(DBURLProtocol*)protocol didFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier
{
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
		
		[self _addPendingSampleInternal:networkSample];
	}];
}

@end
