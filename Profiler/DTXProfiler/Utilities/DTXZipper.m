//
//  DTXZipper.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXZipper.h"
#import "SSZipArchive.h"

NSURL* DTXTempZipURL(void)
{
	return [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:@".containerContents.zip"];
}

BOOL _DTXWriteZipFile(SSZipArchive* zipArchive, NSURL* fileURL)
{
	return [zipArchive writeFileAtPath:fileURL.path withFileName:fileURL.lastPathComponent compressionLevel:0 password:nil AES:NO];
}

BOOL _DTXWriteZipDirectory(SSZipArchive* zipArchive, NSURL* zipURL, NSURL* directoryURL, BOOL prepandDirectory)
{
	BOOL success = YES;
	
	// use a local fileManager (queue/thread compatibility)
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:directoryURL.path];
	NSArray<NSString *> *allObjects = dirEnumerator.allObjects;
	NSString *dirName = directoryURL.lastPathComponent;
	NSString *fileName;
	
	if(prepandDirectory)
	{
		[zipArchive writeFolderAtPath:directoryURL.path withFolderName:dirName withPassword:nil];
	}
	
	for (fileName in allObjects)
	{
		BOOL isDir;
		NSString *fullFilePath = [directoryURL.path stringByAppendingPathComponent:fileName];
		
		if(prepandDirectory)
		{
			fileName = [NSString stringWithFormat:@"%@/%@", dirName, fileName];
		}
		
		if([fullFilePath isEqualToString:zipURL.path])
		{
			continue;
		}
		
		[fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
		
		if (!isDir)
		{
			success &= [zipArchive writeFileAtPath:fullFilePath withFileName:fileName compressionLevel:0 password:nil AES:NO];
		}
		else
		{
			if ([[NSFileManager defaultManager] subpathsOfDirectoryAtPath:fullFilePath error:nil].count == 0)
			{
				success &= [zipArchive writeFolderAtPath:fullFilePath withFolderName:fileName withPassword:nil];
			}
		}
		
		if(success == NO)
		{
			NSLog(@"FAILED for %@", fileName);
		}
	}
	
	return success;
}

BOOL _DTXWriteZipFileWithURLInternal(SSZipArchive* zipArchive, NSURL* zipURL, NSURL* contentsURL)
{
	NSNumber* isDirectory;
	[contentsURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
	
	if(isDirectory.boolValue == YES)
	{
		return _DTXWriteZipDirectory(zipArchive, zipURL, contentsURL, YES);
	}
	else
	{
		return _DTXWriteZipFile(zipArchive, contentsURL);
	}
}

BOOL DTXWriteZipFileWithURLArray(NSURL* zipURL, NSArray<NSURL*>* contentsURLs)
{
	SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:zipURL.path];
	__block BOOL success = [zipArchive open];
	[contentsURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		success &= _DTXWriteZipFileWithURLInternal(zipArchive, zipURL, obj);
		
		if(success == NO)
		{
			NSLog(@"FAILED in DTXWriteZipFileWithURLArray");
		}
		
		*stop = !success;
	}];
	return success & [zipArchive close];
}

BOOL DTXWriteZipFileWithURL(NSURL* zipURL, NSURL* contentsURL)
{
	NSNumber* isDirectory;
	[contentsURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
	
	if(isDirectory.boolValue == YES)
	{
		return DTXWriteZipFileWithDirectoryURL(zipURL, contentsURL);
	}
	else
	{
		return DTXWriteZipFileWithFileURL(zipURL, contentsURL);
	}
}

BOOL DTXWriteZipFileWithFileURL(NSURL* zipURL, NSURL* fileURL)
{
	SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:zipURL.path];
	BOOL success = [zipArchive open];
	success &= _DTXWriteZipFile(zipArchive, fileURL);
	return success & [zipArchive close];
}

BOOL DTXWriteZipFileWithDirectoryURL(NSURL* zipURL, NSURL* directoryURL)
{
	SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:zipURL.path];
	BOOL success = [zipArchive open];
	if (success)
	{
		success &= _DTXWriteZipDirectory(zipArchive, zipURL, directoryURL, NO);
	}
	return success;
}
