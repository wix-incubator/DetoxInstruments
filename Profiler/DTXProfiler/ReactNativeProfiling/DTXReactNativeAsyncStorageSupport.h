//
//  DTXReactNativeAsyncStorageSupport.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 1/12/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXProfilingBasics.h"

@interface DTXReactNativeAsyncStorageSupport : NSObject

+ (void)readAsyncStorageKeysWithCompletionHandler:(void (^)(NSDictionary* asyncStorage))completionHandler;
+ (void)changeAsyncStorageItemWithKey:(NSString*)key changeType:(DTXRemoteProfilingChangeType)changeType value:(id)value previousKey:(NSString*)previousKey completionHandler:(void (^)(void))completionHandler;

@end
