//
//  DTXProfiler.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 18/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfiler.h"
#import "AutoCoding.h"
#import "DTXInstruments+CoreDataModel.h"
#import "NSManagedObject+Additions.h"
#import "DBPerformanceToolkit.h"
#import "DBBuildInfoProvider.h"
#import "DTXZipper.h"
#import "NSManagedObjectContext+PerformQOSBlock.h"
#import "DTXNetworkRecorder.h"
#import "DTXLoggingRecorder.h"
#import "DTXPollingManager.h"

#define DTX_ASSERT_RECORDING NSAssert(self.recording == YES, @"No recording in progress");
#define DTX_ASSERT_NOT_RECORDING NSAssert(self.recording == NO, @"A recording is already in progress");
#define DTX_IGNORE_NOT_RECORDING if(self.recording == NO) { return; }

@implementation DTXProfilingConfiguration

+ (BOOL)supportsSecureCoding
{
	return YES;
}

//Bust be non-kvc compliant so that this property does not end in AutoCoding's dictionaryRepresentation.
@synthesize recordingFileURL = _nonkvc_recordingFileURL;

+ (instancetype)defaultProfilingConfiguration
{
	DTXProfilingConfiguration* rv = [DTXProfilingConfiguration new];;
	rv.recordNetwork = YES;
	rv.recordThreadInformation = YES;
	rv.recordLogOutput = YES;
	rv.samplingInterval = 0.5;
	rv.numberOfSamplesBeforeFlushToDisk = 200;
	
	return rv;
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

+ (NSString*)_fileNameForNewRecording
{
	static NSDateFormatter* dateFileFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFileFormatter = [NSDateFormatter new];
		dateFileFormatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
	});
	
	NSString* dateString = [dateFileFormatter stringFromDate:[NSDate date]];
	return [NSString stringWithFormat:@"%@.dtxprof", [self _sanitizeFileNameString:dateString]];
}

+ (NSURL*)_urlForNewRecording
{
	return [[self _documentsDirectory] URLByAppendingPathComponent:[self _fileNameForNewRecording] isDirectory:YES];
}

- (void)setRecordingFileURL:(NSURL *)recordingFileURL
{
	if(recordingFileURL.isFileURL == NO)
	{
		[NSException raise:NSInvalidArgumentException format:@"URL %@ is not a file URL", recordingFileURL];
		return;
	}
	
	NSNumber* isDirectory;
	[recordingFileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
	
	if(isDirectory)
	{
		recordingFileURL = [recordingFileURL URLByAppendingPathComponent:[DTXProfilingConfiguration _fileNameForNewRecording] isDirectory:YES];
	}
	else
	{
		//Recordings are always directories. If the user provided a file URL, use the file name provided to contruct a directory.
		recordingFileURL = [recordingFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.dtxprof", recordingFileURL.lastPathComponent] isDirectory:YES];
	}
	
	recordingFileURL = recordingFileURL;
}

- (NSURL *)recordingFileURL
{
	if(_nonkvc_recordingFileURL == nil)
	{
		_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	}
	
	return _nonkvc_recordingFileURL;
}

@end

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
	NSUInteger _threadCount;
}

- (void)startProfilingWithConfiguration:(DTXProfilingConfiguration *)configuration
{
	DTX_ASSERT_NOT_RECORDING
	
	self.recording = YES;
	
	_currentProfilingConfiguration = configuration;
	
	_pendingSamples = [NSMutableArray new];
	
	[[NSFileManager defaultManager] createDirectoryAtURL:configuration.recordingFileURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[configuration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXProfiler class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	_threads = [NSMutableDictionary new];
	_threadCount = 0;
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		_backgroundContext = _container.newBackgroundContext;
		
		[_backgroundContext performBlockAndWait:^{
			DBBuildInfoProvider* buildProvider = [DBBuildInfoProvider new];
			NSProcessInfo* processInfo = [NSProcessInfo processInfo];
			UIDevice* currentDevice = [UIDevice currentDevice];
			
			_currentRecording = [[DTXRecording alloc] initWithContext:_backgroundContext];
			_currentRecording.profilingConfiguration = configuration.dictionaryRepresentation;
			_currentRecording.appName = buildProvider.applicationName;
			_currentRecording.binaryName = processInfo.processName;
			_currentRecording.deviceName = currentDevice.name;
			_currentRecording.deviceOS = processInfo.operatingSystemVersionString;
			_currentRecording.deviceOSType = 0; //iOS
			_currentRecording.devicePhysicalMemory = processInfo.physicalMemory;
			_currentRecording.deviceProcessorCount = processInfo.activeProcessorCount;
			_currentRecording.deviceType = currentDevice.model;
			_currentRecording.processIdentifier = processInfo.processIdentifier;
			
			_rootSampleGroup = [[DTXSampleGroup alloc] initWithContext:_backgroundContext];
			_rootSampleGroup.name = @"DTXRoot";
			_rootSampleGroup.recording = _currentRecording;
			_currentSampleGroup = _rootSampleGroup;
			
			__weak __typeof(self) weakSelf = self;
			
			_pollingManager = [[DTXPollingManager alloc] initWithInterval:configuration.samplingInterval];
			[_pollingManager addPollable:[[DBPerformanceToolkit alloc] initWithCollectThreadInfo:configuration.recordThreadInformation] handler:^(DBPerformanceToolkit* pollable) {
				[weakSelf performanceToolkitDidPoll:pollable];
			}];
			[_pollingManager resume];
			
			if(configuration.recordNetwork)
			{
				[DTXNetworkRecorder addNetworkListener:self];
			}
			
			if(configuration.recordLogOutput)
			{
				[DTXLoggingRecorder addLoggingListener:self];
			}
		} qos:QOS_CLASS_USER_INTERACTIVE];
	}];
}

- (void)stopProfilingWithCompletionHandler:(void(^ __nullable)(NSError* __nullable error))handler
{
	DTX_ASSERT_RECORDING
	
	[self _flushPendingSamplesWithInternalCompletionHandler:^{
		_currentRecording.endTimestamp = [NSDate date];
		
		[_backgroundContext save:NULL];
		
		[self _closeContainerInternal];
		
		if(_currentProfilingConfiguration.recordNetwork)
		{
			[DTXNetworkRecorder removeNetworkListener:self];
		}
		
		if(_currentProfilingConfiguration.recordLogOutput)
		{
			[DTXLoggingRecorder removeLoggingListener:self];
		}
		
		_currentProfilingConfiguration = nil;
		
		self.recording = NO;
		
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
		_currentSampleGroup = newGroup;
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)popSampleGroup
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		_currentSampleGroup.closeTimestamp = [NSDate date];
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
		[self _addPendingSampleInternal:tag];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)addLogLine:(NSString *)line
{
	DTX_ASSERT_RECORDING
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXLogSample* log = [[DTXLogSample alloc] initWithContext:_backgroundContext];
		log.parentGroup = _currentSampleGroup;
		log.line = line;
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
	NSJSONWritingOptions jsonOptions = 0;
	if(_currentProfilingConfiguration.prettyPrintJSONOutput == YES)
	{
		jsonOptions |= NSJSONWritingPrettyPrinted;
	}
	
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[_currentRecording dictionaryRepresentation] options:jsonOptions error:NULL];
	NSURL* jsonURL = [_currentProfilingConfiguration.recordingFileURL URLByAppendingPathComponent:@"_dtx_recording.json"];
	[jsonData writeToURL:jsonURL atomically:YES];
	
	[_container.persistentStoreCoordinator.persistentStores.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_container.persistentStoreCoordinator removePersistentStore:obj error:NULL];
	}];
	
	DTXWriteZipFileWithDirectoryContents([_currentProfilingConfiguration.recordingFileURL URLByAppendingPathExtension:@"zip"], _currentProfilingConfiguration.recordingFileURL);
	
//	dprintf(__stderr, "%s\n", [recordingDirectory URLByAppendingPathExtension:@"zip"].path.UTF8String);
	
	_container = nil;
}

- (void)performanceToolkitDidPoll:(DBPerformanceToolkit*)performanceToolkit
{
	DTX_IGNORE_NOT_RECORDING
	
	DTXCPUMeasurement* cpu = performanceToolkit.currentCPU;
	CGFloat memory = performanceToolkit.currentMemory;
	CGFloat fps = performanceToolkit.currentFPS;
	uint64_t diskReads = performanceToolkit.currentDiskReads;
	uint64_t diskWrites = performanceToolkit.currentDiskWrites;
	uint64_t diskReadsDelta = performanceToolkit.currentDiskReadsDelta;
	uint64_t diskWritesDelta = performanceToolkit.currentDiskWritesDelta;
	
	[_backgroundContext performBlock:^{
		DTX_IGNORE_NOT_RECORDING
		
		DTXPerformanceSample* perfSample;
		
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
					NSLog(@"Thread cache-miss");
					threadInfo = [[DTXThreadInfo alloc] initWithContext:_backgroundContext];
					threadInfo.number = _threadCount;
					_threadCount++;
					_threads[@(obj.identifier)] = threadInfo;
				}
				threadInfo.name = obj.name;
				
				DTXThreadPerformanceSample* threadSample = [[DTXThreadPerformanceSample alloc] initWithContext:_backgroundContext];
				threadSample.cpuUsage = obj.cpu;
				threadSample.threadInfo = threadInfo;
				threadSample.advancedPerformanceSample = (DTXAdvancedPerformanceSample*)perfSample;
			}];
		}
		
		perfSample.parentGroup = _currentSampleGroup;
		
		[self _addPendingSampleInternal:perfSample];
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
		
		[self _addPendingSampleInternal:networkSample];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

#pragma DTXLoggingListener

- (void)loggingRecorderDidAddLogLine:(NSString *)logLine
{
	[self addLogLine:logLine];
}

@end
