//
//  DTXExternalProtocolStorage.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXExternalProtocolStorage.h"
@import ObjectiveC;

static dispatch_queue_t __DTXExternalProtocolStorageQueue;
static BOOL __DTXExternalProtocolStorageEnabled;

@class _DTXExternalProtocolStorageEntry;
static NSMapTable<NSURLProtocol*, _DTXExternalProtocolStorageEntry*>* __DTXExternalProtocolsStorageProtocolEntryMapping;

@interface _DTXExternalProtocolStorageEntry : NSObject

@property (nonatomic, copy) NSURLResponse* response;
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, copy) NSError* error;

@end

@implementation _DTXExternalProtocolStorageEntry @end

@implementation _DTXExternalProtocolStorage

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__DTXExternalProtocolStorageQueue = dispatch_queue_create("com.wix.DTXExternalProtocolStorageQueue", DISPATCH_QUEUE_SERIAL);
		__DTXExternalProtocolsStorageProtocolEntryMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
	});
}

+ (void)setEnabled:(BOOL)enabled
{
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		__DTXExternalProtocolStorageEnabled = enabled;
		
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			[__DTXExternalProtocolsStorageProtocolEntryMapping removeAllObjects];
		}
	});
}

+ (void)addProtocolInstance:(NSURLProtocol*)protocolInstance
{
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			return;
		}
		
		[__DTXExternalProtocolsStorageProtocolEntryMapping setObject:[_DTXExternalProtocolStorageEntry new] forKey:protocolInstance];
	});
}

+ (void)setResponse:(NSURLResponse*)response forProtocolInstance:(NSURLProtocol*)protocolInstance
{
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			return;
		}
		
		_DTXExternalProtocolStorageEntry* entry = [__DTXExternalProtocolsStorageProtocolEntryMapping objectForKey:protocolInstance];
		if(entry == nil) { return; }
		
		entry.response = response;
	});
}

+ (void)appendLoadedData:(NSData*)data forProtocolInstance:(NSURLProtocol*)protocolInstance
{
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			return;
		}
		
		_DTXExternalProtocolStorageEntry* entry = [__DTXExternalProtocolsStorageProtocolEntryMapping objectForKey:protocolInstance];
		if(entry == nil) { return; }
		if(entry.data == nil) { entry.data = [NSMutableData new]; }
		
		[entry.data appendData:data];
	});
}

+ (void)setError:(NSError*)error forProtocolInstance:(NSURLProtocol*)protocolInstance
{
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			return;
		}
		
		_DTXExternalProtocolStorageEntry* entry = [__DTXExternalProtocolsStorageProtocolEntryMapping objectForKey:protocolInstance];
		if(entry == nil) { return; }
		
		entry.error = error;
	});
}

+ (void)getResponse:(out NSURLResponse**)response data:(out NSData**)data error:(out NSError**)error forProtocolInstance:(NSURLProtocol*)protocolInstance
{
	__block NSURLResponse* _response;
	__block NSData* _data;
	__block NSError* _error;
	
	dispatch_sync(__DTXExternalProtocolStorageQueue, ^{
		if(__DTXExternalProtocolStorageEnabled == NO)
		{
			return;
		}
		
		_DTXExternalProtocolStorageEntry* entry = [__DTXExternalProtocolsStorageProtocolEntryMapping objectForKey:protocolInstance];
		if(entry == nil) { return; }
		
		_response = entry.response;
		_data = entry.data;
		_error = entry.error;
		
		[__DTXExternalProtocolsStorageProtocolEntryMapping removeObjectForKey:protocolInstance];
	});
	
	*response = _response;
	*data = _data;
	*error = _error;
}

@end
