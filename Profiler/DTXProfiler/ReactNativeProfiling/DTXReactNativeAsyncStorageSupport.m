//
//  DTXReactNativeAsyncStorageSupport.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 1/12/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXReactNativeAsyncStorageSupport.h"
#import "DTXProfilerAPI-Private.h"
@import ObjectiveC;

@interface NSObject ()

- (id)moduleForName:(NSString *)moduleName;
- (id)moduleForName:(NSString *)moduleName lazilyLoadIfNecessary:(BOOL)lazilyLoad;
// Note: This method lazily load the module as necessary.
- (id)moduleForClass:(Class)moduleClass;

- (dispatch_queue_t)methodQueue;

- (void)getAllKeys:(void (^)(NSArray* response))callback;
- (void)clear:(void (^)(NSArray* response))callback;
- (void)multiGet:(NSArray<NSString *> *)keys callback:(void (^)(NSArray* response))callback;
- (void)multiSet:(NSArray<NSArray<NSString *> *> *)kvPairs callback:(void (^)(NSArray* response))callback;
- (void)multiMerge:(NSArray<NSArray<NSString *> *> *)kvPairs callback:(void (^)(NSArray* response))callback;
- (void)multiRemove:(NSArray<NSString *> *)keys callback:(void (^)(NSArray* response))callback;

@end

#define DTXBeginAsyncStorageOperation() \
NSDate* __beginTimestamp = NSDate.date

#define DTXEndFetchAsyncStorageOperation(operation) \
NSDate* __endTimestamp = NSDate.date; \
id __error = response.firstObject; \
__DTXProfilerAddRNAsyncStorageOperation(__beginTimestamp, keys.count, [__endTimestamp timeIntervalSinceDate:__beginTimestamp], 0, 0, operation, NO, response.lastObject, [__error isKindOfClass:NSNull.class] ? nil : __error)

#define DTXEndSaveAsyncStorageOperation(count, operation, isDataKeysOnly, data) \
NSDate* __endTimestamp = NSDate.date; \
id __error = response.firstObject; \
__DTXProfilerAddRNAsyncStorageOperation(__beginTimestamp, 0, 0, count, [__endTimestamp timeIntervalSinceDate:__beginTimestamp], operation, isDataKeysOnly, data, [__error isKindOfClass:NSNull.class] ? nil : __error)

static void (*__orig_DTXMultiGet)(id self, SEL _cmd, NSArray<NSString *> *keys, void (^callback)(NSArray* response));
static void __dtxinst_multiGet(id self, SEL _cmd, NSArray<NSString *> *keys, void (^callback)(NSArray* response))
{
	DTXBeginAsyncStorageOperation();
	__orig_DTXMultiGet(self, _cmd, keys, ^ (NSArray* response) {
		DTXEndFetchAsyncStorageOperation(@"multiGet");
		
		callback(response);
	});
}

static void (*__orig_DTXMultiSet)(id self, SEL _cmd, NSArray<NSArray<NSString *> *> *kvPairs, void (^callback)(NSArray* response));
static void __dtxinst_DTXMultiSet(id self, SEL _cmd, NSArray<NSArray<NSString *> *> *kvPairs, void (^callback)(NSArray* response))
{
	DTXBeginAsyncStorageOperation();
	__orig_DTXMultiSet(self, _cmd, kvPairs, ^ (NSArray* response) {
		DTXEndSaveAsyncStorageOperation(kvPairs.count, @"multiSet", NO, kvPairs);
		
		callback(response);
	});
}

static void (*__orig_DTXMultiMerge)(id self, SEL _cmd, NSArray<NSArray<NSString *> *> *kvPairs, void (^callback)(NSArray* response));
static void __dtxinst_DTXMultiMerge(id self, SEL _cmd, NSArray<NSArray<NSString *> *> *kvPairs, void (^callback)(NSArray* response))
{
	DTXBeginAsyncStorageOperation();
	__orig_DTXMultiMerge(self, _cmd, kvPairs, ^ (NSArray* response) {
		DTXEndSaveAsyncStorageOperation(kvPairs.count, @"multiMerge", NO, kvPairs);
		
		callback(response);
	});
}

static void (*__orig_DTXMultiRemove)(id self, SEL _cmd, NSArray<NSString *> *keys, void (^callback)(NSArray* response));
static void __dtxinst_DTXMultiRemove(id self, SEL _cmd, NSArray<NSString *> *keys, void (^callback)(NSArray* response))
{
	DTXBeginAsyncStorageOperation();
	__orig_DTXMultiRemove(self, _cmd, keys, ^ (NSArray* response) {
		DTXEndSaveAsyncStorageOperation(keys.count, @"multiRemove", YES, keys);
		
		callback(response);
	});
}

static void (*__orig_DTXClear)(id self, SEL _cmd, void (^callback)(NSArray* response));
static void __dtxinst_DTXClear(id self, SEL _cmd, void (^callback)(NSArray* response))
{
	DTXBeginAsyncStorageOperation();
	__orig_DTXClear(self, _cmd, ^ (NSArray* response) {
		DTXEndSaveAsyncStorageOperation(0, @"clear", NO, nil);
		
		callback(response);
	});
}

@implementation DTXReactNativeAsyncStorageSupport

+ (void)load
{
	@autoreleasepool
	{
		Class asyncStorageModuleClass = NSClassFromString(@"RNCAsyncStorage");
		if(asyncStorageModuleClass == nil)
		{
			return;
		}
		
		Method m;
		m = class_getInstanceMethod(asyncStorageModuleClass, @selector(multiGet:callback:));
		__orig_DTXMultiGet = (void*)method_getImplementation(m);
		method_setImplementation(m, (void*)__dtxinst_multiGet);
		
		m = class_getInstanceMethod(asyncStorageModuleClass, @selector(multiSet:callback:));
		__orig_DTXMultiSet = (void*)method_getImplementation(m);
		method_setImplementation(m, (void*)__dtxinst_DTXMultiSet);
		
		m = class_getInstanceMethod(asyncStorageModuleClass, @selector(multiMerge:callback:));
		__orig_DTXMultiMerge = (void*)method_getImplementation(m);
		method_setImplementation(m, (void*)__dtxinst_DTXMultiMerge);
		
		m = class_getInstanceMethod(asyncStorageModuleClass, @selector(multiRemove:callback:));
		__orig_DTXMultiRemove = (void*)method_getImplementation(m);
		method_setImplementation(m, (void*)__dtxinst_DTXMultiRemove);
		
		m = class_getInstanceMethod(asyncStorageModuleClass, @selector(clear:));
		__orig_DTXClear = (void*)method_getImplementation(m);
		method_setImplementation(m, (void*)__dtxinst_DTXClear);
	}
}

+ (void)readAsyncStorageKeysWithCompletionHandler:(void (^)(NSDictionary* asyncStorage))completionHandler
{
	id bridge = [NSClassFromString(@"RCTBridge") valueForKey:@"currentBridge"];
	Class asyncStorageModuleClass = NSClassFromString(@"RNCAsyncStorage");
	if(asyncStorageModuleClass == nil)
	{
		completionHandler(nil);
		
		return;
	}
	
	id module = [bridge moduleForClass:asyncStorageModuleClass];
	dispatch_queue_t storageQueue = [module methodQueue];
	
	dispatch_async(storageQueue, ^{
		[module getAllKeys:^(NSArray *keys) {
			keys = keys.lastObject;
			
			__orig_DTXMultiGet(module, @selector(multiGet:callback:), keys, ^(NSArray *response) {
				NSArray<NSArray<NSString*>*>* pairs = response.lastObject;
				NSMutableDictionary* rv = [NSMutableDictionary new];
				
				[pairs enumerateObjectsUsingBlock:^(NSArray<NSString*>* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
					[rv setObject:obj.lastObject forKey:obj.firstObject];
				}];
				
				completionHandler(rv);
			});
		}];
	});
}

+ (void)changeAsyncStorageItemWithKey:(NSString*)key changeType:(DTXRemoteProfilingChangeType)changeType value:(id)value previousKey:(NSString*)previousKey completionHandler:(void (^)(void))completionHandler
{
	id bridge = [NSClassFromString(@"RCTBridge") valueForKey:@"currentBridge"];
	Class asyncStorageModuleClass = NSClassFromString(@"RNCAsyncStorage");
	if(asyncStorageModuleClass == nil)
	{
		if(completionHandler)
		{
			completionHandler();
		}
		
		return;
	}
	
	id module = [bridge moduleForClass:asyncStorageModuleClass];
	dispatch_queue_t storageQueue = [module methodQueue];
	
	dispatch_async(storageQueue, ^{
		void (^step3)(id unused) = ^ (id unused) {
			if(completionHandler)
			{
				completionHandler();
			}
		};
		
		void (^step2)(id unused) = ^ (id unused) {
			if(changeType == DTXRemoteProfilingChangeTypeClear)
			{
				__orig_DTXClear(module, @selector(clear:), step3);
			}
			else if(changeType == DTXRemoteProfilingChangeTypeDelete)
			{
				__orig_DTXMultiRemove(module, @selector(multiRemove:callback:), @[key], step3);
			}
			else
			{
				__orig_DTXMultiSet(module, @selector(multiSet:callback:), @[@[key, value]], step3);
			}
		};
		
		if(previousKey != nil && [previousKey isEqualToString:key] == NO)
		{
			__orig_DTXMultiRemove(module, @selector(multiRemove:callback:), @[previousKey], step2);
		}
		else
		{
			step2(nil);
		}
	});
}

@end
