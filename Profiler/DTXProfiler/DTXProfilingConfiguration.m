//
//  DTXProfilingConfiguration.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"

@implementation DTXProfilingConfiguration
{
@protected
	NSTimeInterval _samplingInterval;
	NSUInteger _numberOfSamplesBeforeFlushToDisk;
	BOOL _recordNetwork;
	BOOL _recordLocalhostNetwork;
	BOOL _recordThreadInformation;
	BOOL _collectStackTraces;
	BOOL _symbolicateStackTraces;
	BOOL _recordLogOutput;
	BOOL _profileReactNative;
	BOOL _collectJavaScriptStackTraces;
	BOOL _symbolicateJavaScriptStackTraces;
	BOOL _prettyPrintJSONOutput;
	NSURL* _nonkvc_recordingFileURL;
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

//Bust be non-kvc compliant so that this property does not end in AutoCoding's dictionaryRepresentation.
@synthesize recordingFileURL = _nonkvc_recordingFileURL;

+ (instancetype)defaultProfilingConfiguration
{
	DTXProfilingConfiguration* rv = [self new];;
	rv->_recordNetwork = YES;
	rv->_recordThreadInformation = YES;
	rv->_recordLogOutput = YES;
	rv->_samplingInterval = 0.5;
	rv->_numberOfSamplesBeforeFlushToDisk = 200;
	rv->_profileReactNative = YES;
	rv->_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	
	return rv;
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	DTXProfilingConfiguration* rv = self.defaultProfilingConfiguration;
	rv->_samplingInterval = 1.0;
	
	return rv;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	NSURL* recordingFileURL = [aDecoder decodeObjectForKey:@"recordingFileURL"];
	if(recordingFileURL)
	{
		self->_nonkvc_recordingFileURL = recordingFileURL;
	}
	else
	{
		self->_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	DTXProfilingConfiguration* copy = [DTXMutableProfilingConfiguration new];
	
	[DTXProfilingConfiguration.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[copy setValue:[self valueForKey:key] forKey:key];
	}];
	copy->_nonkvc_recordingFileURL = [self recordingFileURL];
	
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
- (void)setSamplingInterval:(NSTimeInterval)samplingInterval
{
	_samplingInterval = samplingInterval;
}

@dynamic numberOfSamplesBeforeFlushToDisk;
- (void)setNumberOfSamplesBeforeFlushToDisk:(NSUInteger)numberOfSamplesBeforeFlushToDisk
{
	_numberOfSamplesBeforeFlushToDisk = numberOfSamplesBeforeFlushToDisk;
}

@dynamic recordNetwork;
- (void)setRecordNetwork:(BOOL)recordNetwork
{
	_recordNetwork = recordNetwork;
}

@dynamic recordLocalhostNetwork;
- (void)setRecordLocalhostNetwork:(BOOL)recordLocalhostNetwork
{
	_recordLocalhostNetwork = recordLocalhostNetwork;
}

@dynamic recordThreadInformation;
- (void)setRecordThreadInformation:(BOOL)recordThreadInformation
{
	_recordThreadInformation = recordThreadInformation;
}

@dynamic collectStackTraces;
- (void)setCollectStackTraces:(BOOL)collectStackTraces
{
	_collectStackTraces = collectStackTraces;
}

@dynamic symbolicateStackTraces;
- (void)setSymbolicateStackTraces:(BOOL)symbolicateStackTraces
{
	_symbolicateStackTraces = symbolicateStackTraces;
}

@dynamic recordLogOutput;
- (void)setRecordLogOutput:(BOOL)recordLogOutput
{
	_recordLogOutput = recordLogOutput;
}

@dynamic profileReactNative;
- (void)setProfileReactNative:(BOOL)profileReactNative
{
	_profileReactNative = profileReactNative;
}

@dynamic collectJavaScriptStackTraces;
- (void)setCollectJavaScriptStackTraces:(BOOL)collectJavaScriptStackTraces
{
	_collectJavaScriptStackTraces = collectJavaScriptStackTraces;
}

@dynamic symbolicateJavaScriptStackTraces;
- (void)setSymbolicateJavaScriptStackTraces:(BOOL)symbolicateJavaScriptStackTraces
{
	_symbolicateJavaScriptStackTraces = symbolicateJavaScriptStackTraces;
}

@dynamic prettyPrintJSONOutput;
- (void)setPrettyPrintJSONOutput:(BOOL)prettyPrintJSONOutput
{
	_prettyPrintJSONOutput = prettyPrintJSONOutput;
}

@dynamic recordingFileURL;
- (void)_setRecordingFileURL:(NSURL *)recordingFileURL
{
	self->_nonkvc_recordingFileURL = recordingFileURL;
}

- (void)setRecordingFileURL:(NSURL *)recordingFileURL
{
	if(recordingFileURL.isFileURL == NO)
	{
		[NSException raise:NSInvalidArgumentException format:@"URL %@ is not a file URL", recordingFileURL];
		return;
	}
	
	NSNumber* isDirectory;
	[recordingFileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
	
	if(isDirectory.boolValue)
	{
		recordingFileURL = [recordingFileURL URLByAppendingPathComponent:[DTXProfilingConfiguration _fileNameForNewRecording] isDirectory:YES];
	}
	else
	{
		//Recordings are always directories. If the user provided a file URL, use the file name provided to contruct a directory.
		recordingFileURL = [recordingFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.dtxprof", recordingFileURL.lastPathComponent] isDirectory:YES];
	}
	
	[self _setRecordingFileURL:recordingFileURL];
}

+ (instancetype)defaultProfilingConfiguration
{
	DTXMutableProfilingConfiguration* rv = [super defaultProfilingConfiguration];
	rv->_nonkvc_recordingFileURL = nil;
	
	return rv;
}

- (id)copyWithZone:(NSZone *)zone
{
	DTXProfilingConfiguration* copy = [DTXProfilingConfiguration new];
	
	[DTXProfilingConfiguration.codableProperties enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
		[copy setValue:[self valueForKey:key] forKey:key];
	}];
	copy->_nonkvc_recordingFileURL = [self recordingFileURL];
	
	return copy;
}

@end
