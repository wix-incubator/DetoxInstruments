//
//  DTXProfilingConfiguration.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration-Private.h"
#import "AutoCoding.h"
#import "NSString+FileNames.h"

@interface DTXProfilingConfiguration ()

@property (nonatomic, readwrite) NSUInteger numberOfSamplesBeforeFlushToDisk;
@property (nonatomic, readwrite) BOOL recordPerformance;
@property (nonatomic, readwrite) NSTimeInterval samplingInterval;
@property (nonatomic, readwrite) BOOL recordThreadInformation;
@property (nonatomic, readwrite) BOOL collectStackTraces;
@property (nonatomic, readwrite) BOOL symbolicateStackTraces;
@property (nonatomic, readwrite) BOOL collectOpenFileNames;
@property (nonatomic, readwrite) BOOL recordNetwork;
@property (nonatomic, readwrite) BOOL recordLocalhostNetwork;
@property (nonatomic, readwrite) BOOL disableNetworkCache;
@property (nonatomic, readwrite) BOOL recordEvents;
@property (nonatomic, copy, readwrite) NSSet<NSString*>* ignoredEventCategories;
@property (nonatomic, readwrite) BOOL recordLogOutput;
@property (nonatomic, readwrite) BOOL profileReactNative;
@property (nonatomic, readwrite) BOOL recordReactNativeBridgeData;
@property (nonatomic, readwrite) BOOL recordReactNativeTimersAsActivity;
@property (nonatomic, copy, null_resettable, readwrite) NSURL* recordingFileURL;
@property (nonatomic, readwrite) BOOL recordInternalReactNativeActivity;
@property (nonatomic, readwrite) NSArray<NSString*>* _ignoredEventCategoriesArray;
@property (nonatomic, readwrite) BOOL recordActivity;

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

- (instancetype)_init
{
	return [super init];
}

- (instancetype)init
{
	return [self.class defaultProfilingConfiguration];
}

//Bust be non-kvc compliant so that this property does not end in AutoCoding's dictionaryRepresentation.
@synthesize recordingFileURL = _nonkvc_recordingFileURL;
@synthesize ignoredEventCategories = _nonkvc_ignoredEventCategories;

+ (instancetype)defaultProfilingConfiguration
{
	DTXProfilingConfiguration* rv = [[self alloc] _init];
	rv->_collectOpenFileNames = NO;
	rv->_recordPerformance = YES;
	rv->_recordNetwork = YES;
	rv->_recordThreadInformation = YES;
	rv->_recordLogOutput = YES;
	rv->_samplingInterval = 0.5;
	rv->_numberOfSamplesBeforeFlushToDisk = 200;
	rv->_profileReactNative = YES;
	rv->_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	rv->_recordEvents = YES;
	rv->_recordActivity = NO;
	rv->_nonkvc_ignoredEventCategories = NSSet.set;
	
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
	
	//Support legacy configurations
	if([aDecoder containsValueForKey:@"recordInternalReactNativeEvents"])
	{
		self.recordInternalReactNativeActivity = [aDecoder decodeBoolForKey:@"recordInternalReactNativeEvents"];
	}
	if([aDecoder containsValueForKey:@"recordReactNativeTimersAsEvents"])
	{
		self.recordReactNativeTimersAsActivity = [aDecoder decodeBoolForKey:@"recordReactNativeTimersAsEvents"];
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
	DTXProfilingConfiguration* copy = [[DTXProfilingConfiguration alloc] _init];
	
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
	DTXProfilingConfiguration* copy = [[DTXMutableProfilingConfiguration alloc] _init];
	
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

DTX_ALWAYS_INLINE
static NSDateFormatter* _DTXDateFormatterForFileName(void)
{
	static NSDateFormatter* dateFileFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFileFormatter = [NSDateFormatter new];
		dateFileFormatter.dateStyle = NSDateFormatterMediumStyle;
		dateFileFormatter.timeStyle = NSDateFormatterMediumStyle;
		dateFileFormatter.dateFormat = [dateFileFormatter.dateFormat stringByReplacingOccurrencesOfString:@":" withString:@"\\"];
	});
	return dateFileFormatter;
}

+ (NSString*)_fileNameForNewRecordingWithAppName:(NSString*)appName date:(NSDate*)date
{
	if(date == nil)
	{
		date = [NSDate date];
	}
	
	NSString* dateString = [_DTXDateFormatterForFileName() stringFromDate:date];
	return [NSString stringWithFormat:@"%@ %@.dtxrec", appName, dateString.stringBySanitizingForFileName];
}

+ (NSURL*)_urlForNewRecordingWithAppName:(NSString*)appName date:(NSDate*)date
{
	return [[self _documentsDirectory] URLByAppendingPathComponent:[self _fileNameForNewRecordingWithAppName:appName date:date] isDirectory:YES];
}

+ (NSURL*)_urlForNewRecording
{
	return [self _urlForNewRecordingWithAppName:NSProcessInfo.processInfo.processName date:nil];
}

+ (NSURL*)_urlForLaunchRecordingWithAppName:(NSString*)appName date:(NSDate*)date
{
	return [[self _documentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"AppLaunchProfiling %@", [self _fileNameForNewRecordingWithAppName:appName date:date]] isDirectory:YES];
}

+ (NSURL*)_urlForLaunchRecordingWithSessionID:(NSString*)session
{
	return [self _urlForLaunchRecordingWithAppName:NSProcessInfo.processInfo.processName date:nil];
}

- (NSURL *)recordingFileURL
{
	return _nonkvc_recordingFileURL;
}

@end

@implementation DTXProfilingConfiguration (Deprecated)

- (BOOL)recordInternalReactNativeEvents
{
	return self.recordInternalReactNativeActivity;
}

- (BOOL)recordReactNativeTimersAsEvents
{
	return self.recordReactNativeTimersAsActivity;
}

@end

@implementation DTXMutableProfilingConfiguration

@dynamic defaultProfilingConfiguration, defaultProfilingConfigurationForRemoteProfiling;

@dynamic numberOfSamplesBeforeFlushToDisk;
@dynamic samplingInterval;
@dynamic recordPerformance;
@dynamic recordThreadInformation;
@dynamic collectStackTraces;
@dynamic symbolicateStackTraces;
@dynamic collectOpenFileNames;
@dynamic recordNetwork;
@dynamic recordLocalhostNetwork;
@dynamic disableNetworkCache;
@dynamic recordEvents;
@dynamic ignoredEventCategories;
@dynamic recordLogOutput;
@dynamic profileReactNative;
@dynamic recordReactNativeBridgeData;
@dynamic recordReactNativeTimersAsActivity;
@dynamic recordInternalReactNativeActivity;
@dynamic recordingFileURL;
@dynamic recordActivity;

- (void)setRecordingFileURL:(NSURL *)recordingFileURL
{
	if(recordingFileURL.isFileURL == NO)
	{
		[NSException raise:NSInvalidArgumentException format:@"URL %@ is not a file URL", recordingFileURL];
		return;
	}
	
	NSNumber* isDirectory;
	[recordingFileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
	
	if(isDirectory.boolValue && [recordingFileURL.lastPathComponent hasSuffix:@"dtxrec"] == NO)
	{
		recordingFileURL = [recordingFileURL URLByAppendingPathComponent:[DTXProfilingConfiguration _fileNameForNewRecordingWithAppName:NSProcessInfo.processInfo.processName date:nil] isDirectory:YES];
	}
	else
	{
		NSString* fileName = [recordingFileURL.lastPathComponent hasSuffix:@"dtxrec"] ? recordingFileURL.lastPathComponent : [NSString stringWithFormat:@"%@.dtxrec", recordingFileURL.lastPathComponent];
		
		//Recordings are always directories. If the user provided a file URL, use the file name provided to contruct a directory.
		recordingFileURL = [recordingFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:fileName isDirectory:YES];
	}
	
	[super setRecordingFileURL:recordingFileURL];
}

@end

@implementation DTXMutableProfilingConfiguration (Deprecated)

- (BOOL)recordReactNativeTimersAsEvents
{
	return self.recordReactNativeTimersAsActivity;
}

- (void)setRecordReactNativeTimersAsEvents:(BOOL)recordReactNativeTimersAsEvents
{
	self.recordReactNativeTimersAsActivity = recordReactNativeTimersAsEvents;
}

- (BOOL)recordInternalReactNativeEvents
{
	return self.recordInternalReactNativeActivity;
}

- (void)setRecordInternalReactNativeEvents:(BOOL)recordInternalReactNativeEvents
{
	self.recordInternalReactNativeActivity = recordInternalReactNativeEvents;
}

@end
