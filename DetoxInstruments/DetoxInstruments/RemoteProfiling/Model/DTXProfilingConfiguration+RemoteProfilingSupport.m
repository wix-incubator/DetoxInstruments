//
//  DTXProfilingConfiguration+RemoteProfilingSupport.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "AutoCoding.h"

@interface DTXProfilingConfiguration ()
@property (nonatomic, copy, readwrite) NSSet<NSString*>* ignoredEventCategories;
@end

@implementation DTXProfilingConfiguration (RemoteProfilingSupport)

+ (void)registerRemoteProfilingDefaults
{
	NSMutableDictionary* registerAsThis = [NSMutableDictionary new];
	[DTXProfilingConfiguration.defaultProfilingConfigurationForRemoteProfiling.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		registerAsThis[[NSString stringWithFormat:@"DTXSelectedProfilingConfiguration_%@", key]] = obj;
	}];
	[NSUserDefaults.standardUserDefaults registerDefaults:registerAsThis];
}

+ (void)resetRemoteProfilingDefaults
{
	[self.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[NSUserDefaults.standardUserDefaults removeObjectForKey:[NSString stringWithFormat:@"DTXSelectedProfilingConfiguration_%@", key]];
	}];
}

+ (instancetype)profilingConfigurationForRemoteProfilingFromDefaults
{
	DTXProfilingConfiguration* rv = self.defaultProfilingConfigurationForRemoteProfiling;
	
	[rv.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		id value = [NSUserDefaults.standardUserDefaults objectForKey:[NSString stringWithFormat:@"DTXSelectedProfilingConfiguration_%@", key]];
		
		if(value)
		{
			[rv setValue:value forKey:key];
		}
	}];
	
	NSArray* categories = [NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"] ?: @[];
	rv.ignoredEventCategories = [NSSet setWithArray:categories];
	
	if(rv.recordPerformance == NO && rv.recordNetwork == NO && rv.recordEvents == NO && rv.profileReactNative == NO)
	{
		[rv setValue:@YES forKey:@"recordPerformance"];
		[rv setValue:@YES forKey:@"recordNetwork"];
		[rv setValue:@YES forKey:@"recordEvents"];
		[rv setValue:@YES forKey:@"profileReactNative"];
	}
	
	return rv;
}

@end
