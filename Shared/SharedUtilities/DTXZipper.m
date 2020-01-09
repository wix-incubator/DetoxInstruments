//
//  DTXZipper.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXZipper.h"
#if __has_include(<ZipZap/ZipZap.h>)
#import <ZipZap/ZipZap.h>
#else
#import "ZipZap.h"
#endif

#if __has_include("DTXLogging.h")
#import "DTXLogging.h"
DTX_CREATE_LOG(DTXZipper)
#define NSLog dtx_log_error
#endif

NSURL* DTXTempZipURL(void)
{
	return [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:@".containerContents.zip"];
}

static NSArray* _DTXZipEntriesForURL(NSURL* contentsURL)
{
	NSMutableArray* entries = [NSMutableArray new];

	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:contentsURL includingPropertiesForKeys:@[NSURLIsDirectoryKey,NSURLNameKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
	
	for (NSURL *fileURL in enumerator)
	{
		NSString* name = [fileURL.path substringFromIndex:contentsURL.path.length];

		NSNumber* isDirectory;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if(isDirectory.boolValue == YES)
		{
			[entries addObject:[ZZArchiveEntry archiveEntryWithDirectoryName:[NSString stringWithFormat:@"%@/", name]]];
		}
		else
		{
			[entries addObject:[ZZArchiveEntry archiveEntryWithFileName:name compress:YES dataBlock:^NSData * _Nullable(NSError * _Nullable __autoreleasing * _Nullable error) {
				return [NSData dataWithContentsOfURL:fileURL];
			}]];
		}
	}
	
//	NSNumber* isDirectory;
//	[contentsURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
//	if(isDirectory.boolValue == YES)
//	{
//
//
//	}
//	else
//	{
//
//	}
	
	return entries;
}

BOOL DTXWriteZipFileWithURLArray(NSURL* zipURL, NSArray<NSURL*>* contentsURLs)
{
	ZZArchive* archive = [[ZZArchive alloc] initWithURL:zipURL options:@{ZZOpenOptionsCreateIfMissingKey : @YES} error:NULL];
	
	NSMutableArray* entries = [NSMutableArray new];
	[contentsURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[entries addObjectsFromArray:_DTXZipEntriesForURL(obj)];
	}];
	
	return [archive updateEntries:entries error:NULL];
}

BOOL DTXWriteZipFileWithURL(NSURL* zipURL, NSURL* contentsURL)
{
	ZZArchive* archive = [[ZZArchive alloc] initWithURL:zipURL options:@{ZZOpenOptionsCreateIfMissingKey : @YES} error:NULL];

	NSArray* entries = _DTXZipEntriesForURL(contentsURL);
	
	return [archive updateEntries:entries error:NULL];
}

BOOL DTXWriteZipFileWithFileURL(NSURL* zipURL, NSURL* fileURL)
{
	return DTXWriteZipFileWithURL(zipURL, fileURL);
}

BOOL DTXWriteZipFileWithDirectoryURL(NSURL* zipURL, NSURL* directoryURL)
{
	return DTXWriteZipFileWithURL(zipURL, directoryURL);
}

BOOL DTXExtractZipToURL(NSURL* zipURL, NSURL* targetURL)
{
	[NSFileManager.defaultManager createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	ZZArchive* archive = [ZZArchive archiveWithURL:zipURL error:NULL];
	
	[archive.entries enumerateObjectsUsingBlock:^(ZZArchiveEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
	{
		NSURL* fullExtractURL = [targetURL URLByAppendingPathComponent:obj.fileName];
		
		BOOL isDirectory = (obj.fileMode & S_IFDIR) != 0;
	
		if(isDirectory)
		{
			[NSFileManager.defaultManager createDirectoryAtURL:fullExtractURL withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		else
		{
			[[obj newDataWithError:NULL] writeToURL:fullExtractURL atomically:YES];
		}
	}];
	
	return YES;
}

BOOL DTXExtractDataZipToURL(NSData* zipData, NSURL* targetURL)
{
	[NSFileManager.defaultManager createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	ZZArchive* archive = [ZZArchive archiveWithData:zipData error:NULL];
	
	[archive.entries enumerateObjectsUsingBlock:^(ZZArchiveEntry * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
	{
		NSURL* fullExtractURL = [targetURL URLByAppendingPathComponent:obj.fileName];
		
		BOOL isDirectory = (obj.fileMode & S_IFDIR) != 0;
	
		if(isDirectory)
		{
			[NSFileManager.defaultManager createDirectoryAtURL:fullExtractURL withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		else
		{
			[[obj newDataWithError:NULL] writeToURL:fullExtractURL atomically:YES];
		}
	}];
	
	return YES;
}
