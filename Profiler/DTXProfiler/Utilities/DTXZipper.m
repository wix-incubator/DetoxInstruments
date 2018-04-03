//
//  DTXZipper.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXZipper.h"
#import "SSZipArchive.h"

extern BOOL DTXWriteZipFileWithDirectoryContents(NSURL* zipURL, NSURL* directoryURL)
{
	SSZipArchive *zipArchive = [[SSZipArchive alloc] initWithPath:zipURL.path];
	BOOL success = [zipArchive open];
	if (success) {
		// use a local fileManager (queue/thread compatibility)
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:directoryURL.path];
		NSArray<NSString *> *allObjects = dirEnumerator.allObjects;
		NSString *fileName;
		for (fileName in allObjects) {
			BOOL isDir;
			NSString *fullFilePath = [directoryURL.path stringByAppendingPathComponent:fileName];
			
			if([fullFilePath isEqualToString:zipURL.path])
			{
				continue;
			}
			
			[fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
			
			if (!isDir) {
				success &= [zipArchive writeFileAtPath:fullFilePath withFileName:fileName compressionLevel:0 password:nil AES:YES];
			}
			else
			{
				if ([[NSFileManager defaultManager] subpathsOfDirectoryAtPath:fullFilePath error:nil].count == 0)
				{
					success &= [zipArchive writeFolderAtPath:fullFilePath withFolderName:fileName withPassword:nil];
				}
			}
		}
		success &= [zipArchive close];
	}
	return success;
}
