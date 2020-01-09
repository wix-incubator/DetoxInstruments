//
//  DTXDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
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
	
	_cachedPreferences = [self _safelyReadCachedPreferencesFromURL:self._preferencesURL];
	
	if(_cachedPreferences == nil)
	{
		_cachedPreferences = [NSMutableDictionary new];
	}
}

- (void)_persistCachedPreferences
{
	NSURL* urlToPersist = self._preferencesURL;
	
	if(urlToPersist == nil)
	{
		return;
	}
	
	[self _safelyPersistCachedPreferencesToURL:urlToPersist];
}

- (void)_safelyPersistCachedPreferencesToURL:(NSURL*)urlToPersist
{
	NSMutableDictionary* safe = [NSMutableDictionary new];
	[_cachedPreferences enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if([NSPropertyListSerialization propertyList:obj isValidForFormat:NSPropertyListXMLFormat_v1_0])
		{
			safe[key] = obj;
		}
		else
		{
			safe[key] = @{
				@"_isArchived": @YES,
				@"data": [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:NULL]
			};
		}
	}];
	
	[safe writeToURL:urlToPersist error:NULL];
}

- (NSMutableDictionary*)_safelyReadCachedPreferencesFromURL:(NSURL*)urlToPersist
{
	NSDictionary* safe = [[NSDictionary alloc] initWithContentsOfURL:urlToPersist];
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	[safe enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		if([obj isKindOfClass:NSDictionary.class] && [[obj objectForKey:@"_isArchived"] boolValue])
		{
			rv[key] = [NSKeyedUnarchiver dtx_unarchiveObjectWithData:[obj objectForKey:@"data"] requiringSecureCoding:NO error:NULL];
		}
		else
		{
			rv[key] = obj;
		}
	}];
	
	return rv;
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
	[self _persistCachedPreferences];
}

- (void)setFileURL:(NSURL *)fileURL
{
	[super setFileURL:fileURL];
	
	[self _reloadCachedPreferencesIfNeeded];
	[self _persistCachedPreferences];
}

- (BOOL)presentError:(NSError *)error
{
	NSAlert* errorAlert = [NSAlert alertWithError:error];
	[errorAlert beginSheetModalForWindow:self.windowControllers.firstObject.window completionHandler:^(NSModalResponse returnCode) {
		[NSApp stopModalWithCode:returnCode];
	}];
	NSModalResponse r = [NSApp runModalForWindow:errorAlert.window];
	
	if(error.localizedRecoveryOptions.count > 0)
	{
		return [error.recoveryAttempter attemptRecoveryFromError:error optionIndex:r - NSAlertFirstButtonReturn];
	}
	
	return NO;
}

@end
