//
//  DTXDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXDocument.h"

@implementation DTXDocument
{
	NSMutableDictionary* _cachedPreferences;
}

- (NSURL*)_preferencesURL
{
	NSURL* loadURL = self.fileURL ?: self.autosavedContentsFileURL;
	return [loadURL URLByAppendingPathComponent:@".preferences.plist"];
}

- (void)_reloadCachedPreferencesIfNeeded
{
	if(_cachedPreferences != nil)
	{
		return;
	}
	
	_cachedPreferences = [[NSMutableDictionary alloc] initWithContentsOfURL:self._preferencesURL];
	
	if(_cachedPreferences == nil)
	{
		_cachedPreferences = [NSMutableDictionary new];
	}
}

- (void)_persistCachedPreferences
{
	[_cachedPreferences writeToURL:self._preferencesURL error:NULL];
}

- (id)objectForPreferenceKey:(NSString *)key
{
	[self _reloadCachedPreferencesIfNeeded];
	
	return _cachedPreferences[key];
}

- (void)setObject:(id)object forPreferenceKey:(NSString *)key
{
	[self _reloadCachedPreferencesIfNeeded];
	
	if([object respondsToSelector:@selector(copy)])
	{
		object = [object copy];
	}
	
	_cachedPreferences[key] = object;
	
	[self _persistCachedPreferences];
}

- (void)setAutosavedContentsFileURL:(NSURL *)autosavedContentsFileURL
{
	[super setAutosavedContentsFileURL:autosavedContentsFileURL];
	
	[self _reloadCachedPreferencesIfNeeded];
}

- (void)setFileURL:(NSURL *)fileURL
{
	[super setFileURL:fileURL];
	
	[self _reloadCachedPreferencesIfNeeded];
}

@end
