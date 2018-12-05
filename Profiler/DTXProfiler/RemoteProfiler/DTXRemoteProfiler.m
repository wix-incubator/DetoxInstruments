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
#import "DTXProfilingBasics.h"
#import "DTXRNJSCSourceMapsSupport.h"
#import "NSManagedObjectContext+PerformQOSBlock.h"

DTX_CREATE_LOG(RemoteProfiler);

@interface DTXProfiler ()

+ (NSManagedObjectModel*)_modelForProfiler;

@end

@interface DTXRemoteProfiler () <DTXProfilerStoryListener>

@end

@implementation DTXRemoteProfiler
{
	DTXSocketConnection* _socketConnection;
	DTXSampleGroup* _currentGroup;
	NSManagedObjectContext* _ctx;
	
	NSMutableDictionary<NSString*, id>* _pendingEvents;
	NSMutableDictionary<NSString*, id>* _pendingNetworkRequests;
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		self._profilerStoryListener = self;
		_pendingEvents = [NSMutableDictionary new];
		_pendingNetworkRequests = [NSMutableDictionary new];
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
	
	NSError* err;
	NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:&err];
	
	NSAssert(plistData != nil, @"Unable to encode data to property list: %@", err.localizedDescription);
	
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

- (void)_addLogLine:(NSString *)line objects:(NSArray *)objects timestamp:(NSDate*)timestamp
{
	[_ctx performBlock:^{
		NSMutableDictionary* preserialized = @{
										@"__dtx_className": @"DTXLogSample",
										@"__dtx_entityName": @"LogSample",
										@"line": line ?: @"",
										@"parentGroup": self->_currentGroup.sampleIdentifier,
										@"sampleIdentifier": NSUUID.UUID.UUIDString,
										@"sampleType": @100,
										@"timestamp": timestamp,
										}.mutableCopy;

		if(objects.count > 0)
		{
			preserialized[objects] = objects;
		}

		[self _serializeCommandWithSelector:NSSelectorFromString(@"addLogSample:") entityName:@"LogSample" dict:preserialized additionalParams:nil];
	} qos:QOS_CLASS_USER_INTERACTIVE];
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
	
	_ctx = recording.managedObjectContext;
}

- (void)_networkRecorderDidStartRequest:(NSURLRequest*)request uniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp
{
	if(self.profilingConfiguration.recordNetwork == NO)
	{
		return;
	}
	
	[_ctx performBlock:^{
		if(self.profilingConfiguration.recordLocalhostNetwork == NO && ([request.URL.host isEqualToString:@"localhost"] || [request.URL.host isEqualToString:@"127.0.0.1"]))
		{
			return;
		}
		
		NSMutableDictionary* preserialized = @{
											   @"__dtx_className": @"DTXNetworkSample",
											   @"__dtx_entityName": @"NetworkSample",
											   @"sampleIdentifier": NSUUID.UUID.UUIDString,
											   @"sampleType": @50,
											   @"parentGroup": self->_currentGroup.sampleIdentifier,
											   @"timestamp": timestamp,
											   @"uniqueIdentifier": uniqueIdentifier,
											   @"url": request.URL.absoluteString,
											   @"requestTimeoutInterval": @(request.timeoutInterval),
											   @"requestDataLength": @(request.HTTPBody.length + request.allHTTPHeaderFields.description.length),
											   }.mutableCopy;
		
		if(request.HTTPMethod.length > 0)
		{
			preserialized[@"requestHTTPMethod"] = request.HTTPMethod;
		}
		
		if(request.allHTTPHeaderFields.count > 0)
		{
			preserialized[@"requestHeaders"] = request.allHTTPHeaderFields;
			preserialized[@"requestHeadersFlat"] = request.allHTTPHeaderFields.debugDescription;
		}
		
		if(request.HTTPBody.length > 0)
		{
			NSDictionary* requestDataPreserialized = @{
													   @"__dtx_className": @"DTXNetworkData",
													   @"__dtx_entityName": @"NetworkData",
													   @"data": request.HTTPBody
													   };
			preserialized[@"requestData"] = requestDataPreserialized;
		}
		
		self->_pendingNetworkRequests[uniqueIdentifier] = preserialized;
		
		[self _serializeCommandWithSelector:NSSelectorFromString(@"startRequestWithNetworkSample:") entityName:@"NetworkSample" dict:preserialized additionalParams:nil];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_networkRecorderDidFinishWithResponse:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error forRequestWithUniqueIdentifier:(NSString*)uniqueIdentifier timestamp:(NSDate*)timestamp
{
	if(self.profilingConfiguration.recordNetwork == NO)
	{
		return;
	}
	
	[_ctx performBlock:^{
		if(self.profilingConfiguration.recordLocalhostNetwork == NO && ([response.URL.host isEqualToString:@"localhost"] || [response.URL.host isEqualToString:@"127.0.0.1"]))
		{
			return;
		}
		
		NSDictionary* request = self->_pendingNetworkRequests[uniqueIdentifier];
		
		if(request == nil)
		{
			return;
		}
		
		NSMutableDictionary* preserialized = @{
											   @"responseTimestamp": timestamp,
											   }.mutableCopy;
		
		if(error.localizedDescription.length > 0)
		{
			preserialized[@"responseError"] = error.localizedDescription;
		}
		
		if(response.MIMEType.length > 0)
		{
			preserialized[@"responseMIMEType"] = response.MIMEType;
		}
		
		NSDictionary* headers;
		if([response isKindOfClass:[NSHTTPURLResponse class]])
		{
			NSHTTPURLResponse* httpResponse = (id)response;
			preserialized[@"responseStatusCode"] = @(httpResponse.statusCode);
			NSString* localizedStatusCodeString = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
			if(localizedStatusCodeString.length > 0)
			{
				preserialized[@"responseStatusCodeString"] = localizedStatusCodeString;
			}
			
			headers = httpResponse.allHeaderFields;
			if(headers.count > 0)
			{
				preserialized[@"responseHeaders"] = headers;
				preserialized[@"responseHeadersFlat"] = headers.debugDescription;
			}
		}
		
		preserialized[@"responseDataLength"] = @(data.length + headers.description.length);
		
		if(data.length > 0)
		{
			NSDictionary* responseDataPreserialized = @{
													   @"__dtx_className": @"DTXNetworkData",
													   @"__dtx_entityName": @"NetworkData",
													   @"data": data
													   };
			preserialized[@"responseData"] = responseDataPreserialized;
		}
		
		preserialized[@"sampleIdentifier"] = request[@"sampleIdentifier"];
		
		[self->_pendingNetworkRequests removeObjectForKey:uniqueIdentifier];
		
		[self _serializeCommandWithSelector:NSSelectorFromString(@"finishWithResponseForNetworkSample:") entityName:@"NetworkSample" dict:preserialized additionalParams:nil];
	}];
}

- (void)_addRNDataFromFunction:(NSString*)function arguments:(NSArray<NSString*>*)arguments returnValue:(NSString*)rv exception:(NSString*)exception isFromNative:(BOOL)isFromNative timestamp:(NSDate*)timestamp;
{
	NSMutableDictionary* preserializedData = @{
										@"__dtx_className": @"DTXReactNativeBridgeData",
										@"__dtx_entityName": @"ReactNativeBridgeData",
										@"returnValue": rv ?: @"null"
										}.mutableCopy;
	
	if(exception.length > 0)
	{
		preserializedData[@"exception"] = exception;
	}
	
	if(arguments.count > 0)
	{
		preserializedData[@"arguments"] = arguments;
	}
	
	NSMutableDictionary* preserialized = @{
									@"__dtx_className": @"DTXReactNativeDataSample",
									@"__dtx_entityName": @"ReactNativeDataSample",
									@"parentGroup": _currentGroup.sampleIdentifier,
									@"sampleIdentifier": NSUUID.UUID.UUIDString,
									@"sampleType": @10001,
									@"timestamp": timestamp,
									@"isFromNative": @(isFromNative),
									@"data": preserializedData
									}.mutableCopy;
	
	if(function.length > 0)
	{
		preserialized[@"function"] = function;
	}
	
	[self _serializeCommandWithSelector:NSSelectorFromString(@"addRNBridgeDataSample:") entityName:@"ReactNativeDataSample" dict:preserialized additionalParams:nil];
}

- (void)popSampleGroup:(DTXSampleGroup *)sampleGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:nil];
	
	_currentGroup = sampleGroup.parentGroup;
	
	[sampleGroup.managedObjectContext deleteObject:sampleGroup];
	[sampleGroup.managedObjectContext save:NULL];
}

- (void)pushSampleGroup:(DTXSampleGroup *)sampleGroup isRootGroup:(BOOL)isRootGroup
{
	[self _serializeCommandWithSelector:_cmd managedObject:sampleGroup additionalParams:@[@(isRootGroup)]];
	
	_currentGroup = sampleGroup;
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

- (void)_markEventIntervalBeginWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name additionalInfo:(NSString*)additionalInfo isTimer:(BOOL)isTimer stackTrace:(NSArray*)stackTrace timestamp:(NSDate*)timestamp
{
	[_ctx performBlock:^{
		
		if([self.profilingConfiguration.ignoredEventCategories containsObject:category])
		{
			return;
		}
		
		NSDictionary* preserialized = @{
										@"__dtx_className": @"DTXSignpostSample",
										@"__dtx_entityName": @"SignpostSample",
										@"additionalInfoStart": additionalInfo ?: @"",
										@"category": category ?: @"",
										@"duration": @0,
										@"eventStatus": @0,
										@"name": name ?: @"",
										@"parentGroup": self->_currentGroup.sampleIdentifier,
										@"sampleIdentifier": identifier,
										@"sampleType": @70,
										@"timestamp": timestamp,
										@"uniqueIdentifier": NSUUID.UUID.UUIDString
										};
		
		self->_pendingEvents[identifier] = preserialized;
		
		[self _serializeCommandWithSelector:NSSelectorFromString(@"markEventIntervalBegin:") entityName:@"SignpostSample" dict:preserialized additionalParams:nil];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_markEventIntervalEndWithIdentifier:(NSString*)identifier eventStatus:(DTXEventStatus)eventStatus additionalInfo:(nullable NSString*)additionalInfo timestamp:(NSDate*)timestamp
{
	[_ctx performBlock:^{
		NSDictionary* event = self->_pendingEvents[identifier];
		
		if(event == nil)
		{
			return;
		}
		
		NSDictionary* preserialized = @{
										@"__dtx_className": @"DTXSignpostSample",
										@"__dtx_entityName": @"SignpostSample",
										@"additionalInfoEnd": additionalInfo ?: @"",
										@"eventStatus": @(eventStatus),
										@"endTimestamp": timestamp,
										@"sampleIdentifier": identifier,
										@"duration": @([timestamp timeIntervalSinceDate:event[@"timestamp"]]),
										};
		[self _serializeCommandWithSelector:NSSelectorFromString(@"markEventIntervalEnd:") entityName:@"SignpostSample" dict:preserialized additionalParams:nil];
		
		[self->_pendingEvents removeObjectForKey:identifier];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)_markEventWithIdentifier:(NSString*)identifier category:(NSString*)category name:(NSString*)name eventStatus:(DTXEventStatus)eventStatus additionalInfo:(NSString*)additionalInfo timestamp:(NSDate*)timestamp
{
	[_ctx performBlock:^{
		
		if([self.profilingConfiguration.ignoredEventCategories containsObject:category])
		{
			return;
		}
		
		NSDictionary* preserialized = @{
										@"__dtx_className": @"DTXSignpostSample",
										@"__dtx_entityName": @"SignpostSample",
										@"additionalInfoStart": additionalInfo ?: @0,
										@"category": category ?: @0,
										@"duration": @0,
										@"isEvent": @1,
										@"eventStatus": @(eventStatus),
										@"name": name ?: @0,
										@"parentGroup": self->_currentGroup.sampleIdentifier,
										@"sampleIdentifier": NSUUID.UUID.UUIDString,
										@"sampleType": @70,
										@"timestamp": timestamp,
										@"endTimestamp": timestamp,
										@"uniqueIdentifier": NSUUID.UUID.UUIDString
										};
		[self _serializeCommandWithSelector:NSSelectorFromString(@"markEvent:") entityName:@"SignpostSample" dict:preserialized additionalParams:nil];
	} qos:QOS_CLASS_USER_INTERACTIVE];
}

- (void)addLogSample:(DTXLogSample *)logSample {}
- (void)markEvent:(DTXSignpostSample *)signpostSample {}
- (void)markEventIntervalBegin:(DTXSignpostSample *)signpostSample {}
- (void)markEventIntervalEnd:(DTXSignpostSample *)signpostSample {}
- (void)startRequestWithNetworkSample:(DTXNetworkSample *)networkSample {}
- (void)finishWithResponseForNetworkSample:(DTXNetworkSample *)networkSample {}
- (void)addRNBridgeDataSample:(DTXReactNativeDataSample*)rbBridgeDataSample {}

@end

