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

+ (BOOL)supportsSecureCoding
{
	return YES;
}

//Bust be non-kvc compliant so that this property does not end in AutoCoding's dictionaryRepresentation.
@synthesize recordingFileURL = _nonkvc_recordingFileURL;

+ (instancetype)defaultProfilingConfiguration
{
	DTXProfilingConfiguration* rv = [DTXProfilingConfiguration new];;
	rv.recordNetwork = YES;
	rv.recordThreadInformation = YES;
	rv.recordLogOutput = YES;
	rv.samplingInterval = 0.5;
	rv.numberOfSamplesBeforeFlushToDisk = 200;
	rv.profileReactNative = YES;
	
	return rv;
}

+ (instancetype)defaultProfilingConfigurationForRemoteProfiling
{
	DTXProfilingConfiguration* rv = self.defaultProfilingConfiguration;
	rv.samplingInterval = 1.0;
	
	return rv;
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
		dateFileFormatter.dateFormat = [dateFileFormatter.dateFormat stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	});
	
	NSString* dateString = [dateFileFormatter stringFromDate:[NSDate date]];
	return [NSString stringWithFormat:@"%@ %@.dtxprof", [NSProcessInfo processInfo].processName, [self _sanitizeFileNameString:dateString]];
}

+ (NSURL*)_urlForNewRecording
{
	return [[self _documentsDirectory] URLByAppendingPathComponent:[self _fileNameForNewRecording] isDirectory:YES];
}

- (void)_setRecordingFileURL:(NSURL *)recordingFileURL
{
	_nonkvc_recordingFileURL = recordingFileURL;
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

- (NSURL *)recordingFileURL
{
	if(_nonkvc_recordingFileURL == nil)
	{
		_nonkvc_recordingFileURL = [DTXProfilingConfiguration _urlForNewRecording];
	}
	
	return _nonkvc_recordingFileURL;
}

@end
