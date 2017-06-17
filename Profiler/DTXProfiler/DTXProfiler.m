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
#import "DTXZipper.h"

#define DTX_ASSERT_RECORDING NSAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING NSAssert(self.recording == NO, @"A recording is already in progress");

static dispatch_queue_t __log_queue;
static dispatch_io_t __log_io;
static int __stderr;
static int __pipe[2];
static NSMutableArray<__kindof DTXProfiler*>* __runningProfilers;

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

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__runningProfilers = [NSMutableArray new];
		[self redirectLogOutput];
	});
}

+ (void)redirectLogOutput
{
	__stderr = dup(STDERR_FILENO);
	
	if (pipe(__pipe) != 0)
	{
		return;
	}
	
	dup2(__pipe[1], STDERR_FILENO);
	close(__pipe[1]);
	
	__log_queue = dispatch_queue_create("DTXProfilerLogIOQueue", DISPATCH_QUEUE_SERIAL);
	__log_io = dispatch_io_create(DISPATCH_IO_STREAM, __pipe[0], __log_queue, ^(__unused int error) {});
	
	dispatch_io_set_low_water(__log_io, 20);
	
	dispatch_io_read(__log_io, 0, SIZE_MAX, __log_queue, ^(__unused bool done, dispatch_data_t data, __unused int error) {
		if (!data)
		{
			return;
		}
		
		dispatch_data_apply(data, ^bool(__unused dispatch_data_t region, __unused size_t offset, const void *buffer, size_t size) {
			write(__stderr, buffer, size);
			
			NSString *log = [[NSString alloc] initWithBytes:buffer length:size encoding:NSUTF8StringEncoding];
			
			[__runningProfilers enumerateObjectsUsingBlock:^(__kindof DTXProfiler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				[obj addLogLine:log];
			}];
			
			return true;
		});
	});
}


+ (NSString *)_sanitizeFileNameString:(NSString *)fileName {
	NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
	return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

+ (NSURL*)_documentsDirectory
{
	return [NSURL fileURLWithPath:@"/Users/lnatan/Desktop/"];
	//	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
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
	return [[self _documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.dtxprof", [self _sanitizeFileNameString:dateString]]];
}

- (void)startProfilingWithOptions:(DTXProfilingOptions *)options
{
	DTX_ASSERT_NOT_RECORDING
	
	self.recording = YES;
	
	_currentProfilingOptions = options;
	
	_pendingSamples = [NSMutableArray new];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[[DTXProfiler _documentsDirectory] URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
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
			_rootSampleGroup.name = @"DTXRoot";
			_rootSampleGroup.recording = _currentRecording;
			_currentSampleGroup = _rootSampleGroup;
			
			_performanceToolkit = [DBPerformanceToolkit new];
			_performanceToolkit.delegate = self;
			
			DBURLProtocol.delegate = self;
			[NSURLProtocol registerClass:[DBURLProtocol class]];
			
			dispatch_sync(__log_queue, ^{
				[__runningProfilers addObject:self];
			});
		}];
	}];
}

- (void)stopProfiling
{
	DTX_ASSERT_RECORDING
	
	[self _flushPendingSamplesWithInternalCompletionHandler:^{
		_currentRecording.endTimestamp = [NSDate date];
		
		[_backgroundContext save:NULL];
		
		[self _closeContainerInternal];
		
		[NSURLProtocol unregisterClass:[DBURLProtocol class]];
		
		_currentProfilingOptions = nil;
		
		dispatch_sync(__log_queue, ^{
			[__runningProfilers removeObject:self];
		});
		
		self.recording = NO;
	}];
}

- (void)pushSampleGroupWithName:(NSString*)name
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING;
		
		dprintf(__stderr, "Pushing group named %s to parent %s\n", name.UTF8String, _currentSampleGroup.name.UTF8String);
		DTXSampleGroup* newGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
		newGroup.name = name;
		newGroup.parentGroup = _currentSampleGroup;
		_currentSampleGroup = newGroup;
	}];
}

- (void)popSampleGroup
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING
		
		dprintf(__stderr, "Popping group named %s from parent %s\n", _currentSampleGroup.name.UTF8String, _currentSampleGroup.parentGroup.name.UTF8String);
		_currentSampleGroup.closeTimestamp = [NSDate date];
		_currentSampleGroup = _currentSampleGroup.parentGroup;
	}];
}

- (void)addTag:(NSString*)_tag
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING
		
		DTXTag* tag = [[DTXTag alloc] initWithContext:_backgroundContext];
		tag.parentGroup = _currentSampleGroup;
		tag.name = _tag;
		[self _addPendingSampleInternal:tag];
	}];
}

- (void)addLogLine:(NSString *)line
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_ASSERT_RECORDING
		
		DTXLogSample* log = [[DTXLogSample alloc] initWithContext:_backgroundContext];
		log.parentGroup = _currentSampleGroup;
		log.line = line;
		[self _addPendingSampleInternal:log];
	}];
}

- (void)_flushPendingSamplesInternal
{
	dprintf(__stderr, "Flushing\n");
	
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
	}];
}

- (void)_closeContainerInternal
{
	dprintf(__stderr, "Closing\n");
	
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[_currentRecording dictionaryRepresentation] options:NSJSONWritingPrettyPrinted error:NULL];
	NSURL* jsonURL = [[DTXProfiler _documentsDirectory] URLByAppendingPathComponent:@"_dtx_recording.json"];
	[jsonData writeToURL:jsonURL atomically:YES];
	
	[_container.persistentStoreCoordinator.persistentStores.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
	NSURL* recordingDirectory = [DTXProfiler _urlForNewRecording];
	[[NSFileManager defaultManager] createDirectoryAtURL:recordingDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSURL* recordingURL = [(id)_container.persistentStoreDescriptions.firstObject URL];
	NSArray<NSURL*>* files = [[[NSFileManager defaultManager] enumeratorAtURL:recordingURL.URLByDeletingLastPathComponent includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:NULL].allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"path contains[cd] %@", recordingURL.lastPathComponent]];
	
	[files enumerateObjectsUsingBlock:^(NSURL* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSError* err;
		
		NSURL* targetURL = [recordingDirectory URLByAppendingPathComponent:obj.lastPathComponent];
		[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
		if([[NSFileManager defaultManager] moveItemAtURL:obj toURL:targetURL error:&err] == NO)
		{
			dprintf(__stderr, "Error moving file %s error: %s\n", obj.lastPathComponent.UTF8String, err.description.UTF8String);
		}
	}];
	
	NSError* err;
	
	NSURL* targetURL = [recordingDirectory URLByAppendingPathComponent:jsonURL.lastPathComponent];
	[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
	if([[NSFileManager defaultManager] moveItemAtURL:jsonURL toURL:targetURL error:&err] == NO)
	{
		dprintf(__stderr, "Error moving file %s error: %s\n", jsonURL.lastPathComponent.UTF8String, err.description.UTF8String);
	}
	
	err = nil;
	
	//	DTXWriteZipFileWithDirectoryContents([recordingDirectory URLByAppendingPathExtension:@"zip"], recordingDirectory);
	
	dprintf(__stderr, "%s\n", [recordingDirectory URLByAppendingPathExtension:@"zip"].path.UTF8String);
	
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
	uint64_t diskReads = performanceToolkit.currentDiskReads;
	uint64_t diskWrites = performanceToolkit.currentDiskWrites;
	uint64_t diskReadsDelta = performanceToolkit.currentDiskReadsDelta;
	uint64_t diskWritesDelta = performanceToolkit.currentDiskWritesDelta;
	
	[_backgroundContext performBlock:^{
		if(self.recording == NO)
		{
			return;
		}
		
		//		DTXAdvancedPerformanceSample* perfSample = [[DTXAdvancedPerformanceSample alloc] initWithContext:_backgroundContext];
		DTXPerformanceSample* perfSample = [[DTXPerformanceSample alloc] initWithContext:_backgroundContext];
		perfSample.cpuUsage = cpu;
		perfSample.memoryUsage = memory;
		perfSample.fps = fps;
		perfSample.diskReads = diskReads;
		perfSample.diskReadsDelta = diskReadsDelta;
		perfSample.diskWrites = diskWrites;
		perfSample.diskWritesDelta = diskWritesDelta;
		
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
	if(self.recording == NO)
	{
		return;
	}
	
	[_backgroundContext performBlock:^{
		if(self.recording == NO)
		{
			return;
		}
		
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
		networkSample.responseDataLength = data.length + networkSample.responseHeaders.description.length;
		
		networkSample.totalDataLength = networkSample.requestDataLength + networkSample.responseDataLength;
		
		[self _addPendingSampleInternal:networkSample];
	}];
}

@end
