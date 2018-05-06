//
//  DTXProfilingConfiguration+RemoteProfilingSupport.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "AutoCoding.h"

@implementation DTXProfilingConfiguration (RemoteProfilingSupport)

- (void)setAsDefaultRemoteProfilingConfiguration
{
	[self.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		[[NSUserDefaults standardUserDefaults] setObject:obj forKey:[NSString stringWithFormat:@"DTXSelectedProfilingConfiguration_%@", key]];
	}];
}

+ (instancetype)profilingConfigurationForRemoteProfilingFromDefaults
{
	DTXProfilingConfiguration* rv = self.defaultProfilingConfigurationForRemoteProfiling;
	
	[rv.dictionaryRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		[rv setValue:[NSUserDefaults.standardUserDefaults objectForKey:[NSString stringWithFormat:@"DTXSelectedProfilingConfiguration_%@", key]] forKey:key];
	}];
	
	return rv;
}

@end
