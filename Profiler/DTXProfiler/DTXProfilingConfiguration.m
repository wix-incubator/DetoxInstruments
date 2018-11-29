//
//  DTXProfilingConfiguration.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"

@interface DTXProfilingConfiguration ()

@property (nonatomic, readwrite) NSTimeInterval samplingInterval;
@property (nonatomic, readwrite) NSUInteger numberOfSamplesBeforeFlushToDisk;
@property (nonatomic, readwrite) BOOL recordThreadInformation;
@property (nonatomic, readwrite) BOOL collectStackTraces;
@property (nonatomic, readwrite) BOOL symbolicateStackTraces;
@property (nonatomic, readwrite) BOOL collectOpenFileNames;
@property (nonatomic, readwrite) BOOL recordNetwork;
@property (nonatomic, readwrite) BOOL recordLocalhostNetwork;
@property (nonatomic, readwrite) BOOL disableNetworkCache;
@property (nonatomic, copy, readwrite) NSSet<NSString*>* ignoredEventCategories;
@property (nonatomic, readwrite) BOOL recordLogOutput;
@property (nonatomic, readwrite) BOOL profileReactNative;
@property (nonatomic, readwrite) BOOL recordReactNativeBridgeData;
@property (nonatomic, readwrite) BOOL recordReactNativeTimersAsEvents;
@property (nonatomic, copy, null_resettable, readwrite) NSURL* recordingFileURL;
@property (nonatomic, readwrite) NSArray<NSString*>* _ignoredEventCategoriesArray;

@end

@implementation DTXProfilingConfiguration
{
@protected
	NSURL* _nonkvc_recordingFileURL;
	NSSet* _nonkvc_ignoredEventCategories;
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

//Bust be non-kvc compliant so that this property does not end in AutoCoding's dictionaryRepresentation.
@synthesize recordingFileURL = _nonkvc_recordingFileURL;
@synthesize ignoredEventCategories = _nonkvc_ignoredEventCategories;

+ (instancetype)defaultProfilingConfiguration
{
	DTXProfilingConfiguration* rv = [self new];
	rv->_collectOpenFileNames = NO;
	rv->_recordNetwork = YES;
	rv->_recordThreadInformation = YES;
	rv->_recordLogOutput = YES;
	rv->_samplingInterval = 1.0;
	rv->_numberOfSamplesBeforeFlushToDisk = 200;
	rv->_profileReactNative = YES;
	rv->_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	rv->_nonkvc_ignoredEventCategories = [NSSet new];
	
	return rv;
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	DTXProfilingConfiguration* rv = self.defaultProfilingConfiguration;
	
	return rv;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	NSURL* recordingFileURL = [aDecoder decodeObjectForKey:@"recordingFileURL"];
	if(recordingFileURL)
	{
		_nonkvc_recordingFileURL = recordingFileURL;
	}
	else
	{
		_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	}
	NSArray* categoriesArray = [aDecoder decodeObjectForKey:@"_ignoredEventCategoriesArray"];
	if(categoriesArray != nil)
	{
		_nonkvc_ignoredEventCategories = [NSSet setWithArray:categoriesArray];
	}
	
	return self;
}

- (NSSet<NSString *> *)ignoredEventCategories
{
	return _nonkvc_ignoredEventCategories ?: [NSSet new];
}

- (void)setIgnoredEventCategories:(NSSet<NSString *> *)ignoredEventCategories
{
	_nonkvc_ignoredEventCategories = [ignoredEventCategories copy];
}

- (NSArray<NSString *> *)_ignoredEventCategoriesArray
{
	return _nonkvc_ignoredEventCategories.allObjects;
}

- (DTXProfilingConfiguration *)copy
{
	return [super copy];
}

- (id)copyWithZone:(NSZone *)zone
{
	DTXProfilingConfiguration* copy = [DTXProfilingConfiguration new];
	
	[DTXProfilingConfiguration.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[copy setValue:[self valueForKey:key] forKey:key];
	}];
	copy->_nonkvc_recordingFileURL = [self recordingFileURL];
	copy->_nonkvc_ignoredEventCategories = [self->_nonkvc_ignoredEventCategories copy];
	
	return copy;
}

- (DTXMutableProfilingConfiguration *)mutableCopy
{
	return [super mutableCopy];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	DTXProfilingConfiguration* copy = [DTXMutableProfilingConfiguration new];
	
	[DTXProfilingConfiguration.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[copy setValue:[self valueForKey:key] forKey:key];
	}];
	copy->_nonkvc_recordingFileURL = [self recordingFileURL];
	copy->_nonkvc_ignoredEventCategories = [self->_nonkvc_ignoredEventCategories copy];
	
	return copy;
}

+ (NSURL*)_documentsDirectory
{
//	return [NSURL fileURLWithPath:@"/Users/lnatan/Desktop/"];
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)_sanitizeFileNameString:(NSString *)fileName {
	NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
	return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

+ (NSString*)_fileNameForNewRecording
{
	static NSDateFormatter* dateFileFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFileFormatter = [NSDateFormatter new];
		dateFileFormatter.dateStyle = NSDateFormatterMediumStyle;
		dateFileFormatter.timeStyle = NSDateFormatterMediumStyle;
		dateFileFormatter.dateFormat = [dateFileFormatter.dateFormat stringByReplacingOccurrencesOfString:@":" withString:@"\\"];
	});
	
	NSString* dateString = [dateFileFormatter stringFromDate:[NSDate date]];
	return [NSString stringWithFormat:@"%@ %@.dtxprof", [NSProcessInfo processInfo].processName, [self _sanitizeFileNameString:dateString]];
}

+ (NSURL*)_urlForNewRecording
{
	return [[self _documentsDirectory] URLByAppendingPathComponent:[self _fileNameForNewRecording] isDirectory:YES];
}

- (NSURL *)recordingFileURL
{
	return _nonkvc_recordingFileURL;
}

@end

@implementation DTXMutableProfilingConfiguration

@dynamic samplingInterval;
@dynamic numberOfSamplesBeforeFlushToDisk;
@dynamic recordThreadInformation;
@dynamic collectStackTraces;
@dynamic symbolicateStackTraces;
@dynamic collectOpenFileNames;
@dynamic recordNetwork;
@dynamic recordLocalhostNetwork;
@dynamic disableNetworkCache;
@dynamic ignoredEventCategories;
@dynamic recordLogOutput;
@dynamic profileReactNative;
@dynamic recordReactNativeBridgeData;
@dynamic recordReactNativeTimersAsEvents;
@dynamic recordingFileURL;

- (void)setRecordingFileURL:(NSURL *)recordingFileURL
{
	if(recordingFileURL.isFileURL == NO)
	{
		[NSException raise:NSInvalidArgumentException format:@"URL %@ is not a file URL", recordingFileURL];
		return;
	}
	
	NSNumber* isDirectory;
	[recordingFileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
	
	if(isDirectory.boolValue && [recordingFileURL.lastPathComponent hasSuffix:@"dtxprof"] == NO)
	{
		recordingFileURL = [recordingFileURL URLByAppendingPathComponent:[DTXProfilingConfiguration _fileNameForNewRecording] isDirectory:YES];
	}
	else
	{
		NSString* fileName = [recordingFileURL.lastPathComponent hasSuffix:@"dtxprof"] ? recordingFileURL.lastPathComponent : [NSString stringWithFormat:@"%@.dtxprof", recordingFileURL.lastPathComponent];
		
		//Recordings are always directories. If the user provided a file URL, use the file name provided to contruct a directory.
		recordingFileURL = [recordingFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:fileName isDirectory:YES];
	}
	
	[super setRecordingFileURL:recordingFileURL];
}

@end
