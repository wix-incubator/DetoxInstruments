//
//  DTXZipper.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXZipper.h"
#include "zip.h"

#define CHUNK 16384

static NSString* __DTXTemporaryPathForDiscardableFile()
{
	static NSString *discardableFileName = @".DS_Store";
	static NSString *discardableFilePath = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *temporaryDirectoryName = [[NSUUID UUID] UUIDString];
		NSString *temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryDirectoryName];
		BOOL directoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		if (directoryCreated) {
			discardableFilePath = [temporaryDirectory stringByAppendingPathComponent:discardableFileName];
			[@"" writeToFile:discardableFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
	});
	return discardableFilePath;
}


static void __DTXZipInfo(zip_fileinfo* zipInfo, NSDate* date)
{
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
#if defined(__IPHONE_8_0) || defined(__MAC_10_10)
	uint flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
#else
	uint flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
#endif
	NSDateComponents *components = [currentCalendar components:flags fromDate:date];
	zipInfo->tmz_date.tm_sec = (unsigned int)components.second;
	zipInfo->tmz_date.tm_min = (unsigned int)components.minute;
	zipInfo->tmz_date.tm_hour = (unsigned int)components.hour;
	zipInfo->tmz_date.tm_mday = (unsigned int)components.day;
	zipInfo->tmz_date.tm_mon = (unsigned int)components.month - 1;
	zipInfo->tmz_date.tm_year = (unsigned int)components.year;
}

static BOOL __DTXWriteFileAtPathToZip(zipFile _zip, NSString* path, NSString* fileName)//:(NSString *)path withFileName:(nullable NSString *)fileName withPassword:(nullable NSString *)password
{
	NSCAssert((_zip != NULL), @"Attempting to write to an archive which was never opened");
	
	FILE *input = fopen([path fileSystemRepresentation], "r");
	if (NULL == input) {
		return NO;
	}
	
	const char *afileName;
	if (!fileName) {
		afileName = [path.lastPathComponent fileSystemRepresentation];
	}
	else {
		afileName = [fileName fileSystemRepresentation];
	}
	
	zip_fileinfo zipInfo = {{0}};
	
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error: nil];
	if (attr)
	{
		NSDate *fileDate = (NSDate *)attr[NSFileModificationDate];
		if (fileDate)
		{
			__DTXZipInfo(&zipInfo, fileDate);
		}
		
		// Write permissions into the external attributes, for details on this see here: http://unix.stackexchange.com/a/14727
		// Get the permissions value from the files attributes
		NSNumber *permissionsValue = (NSNumber *)attr[NSFilePosixPermissions];
		if (permissionsValue != nil) {
			// Get the short value for the permissions
			short permissionsShort = permissionsValue.shortValue;
			
			// Convert this into an octal by adding 010000, 010000 being the flag for a regular file
			NSInteger permissionsOctal = 0100000 + permissionsShort;
			
			// Convert this into a long value
			uLong permissionsLong = @(permissionsOctal).unsignedLongValue;
			
			// Store this into the external file attributes once it has been shifted 16 places left to form part of the second from last byte
			zipInfo.external_fa = permissionsLong << 16L;
		}
	}
	
	void *buffer = malloc(CHUNK);
	if (buffer == NULL)
	{
		return NO;
	}
	
	zipOpenNewFileInZip3(_zip, afileName, &zipInfo, NULL, 0, NULL, 0, NULL, Z_DEFLATED, Z_DEFAULT_COMPRESSION, 0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, NULL, 0);
	unsigned int len = 0;
	
	while (!feof(input) && !ferror(input))
	{
		len = (unsigned int) fread(buffer, 1, CHUNK, input);
		zipWriteInFileInZip(_zip, buffer, len);
	}
	
	zipCloseFileInZip(_zip);
	free(buffer);
	fclose(input);
	return YES;
}

extern BOOL DTXWriteZipFileWithDirectoryContents(NSURL* url, NSURL* directoryURL)
{
	BOOL success = NO;
	
	NSFileManager *fileManager = nil;
	zipFile _zip;
	_zip = zipOpen(url.fileSystemRepresentation, APPEND_STATUS_CREATE);
	
	if (_zip != NULL)
	{
		fileManager = [[NSFileManager alloc] init];
		NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:directoryURL.path];
		NSArray *allObjects = dirEnumerator.allObjects;
		NSString *fileName;
		for (fileName in allObjects) {
			BOOL isDir;
			NSString *fullFilePath = [directoryURL.path stringByAppendingPathComponent:fileName];
			[fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
			fileName = [[directoryURL.path lastPathComponent] stringByAppendingPathComponent:fileName];
			
			if (!isDir) {
				__DTXWriteFileAtPathToZip(_zip, fullFilePath, fileName);
			}
			else
			{
				if ([[NSFileManager defaultManager] subpathsOfDirectoryAtPath:fullFilePath error:nil].count == 0)
				{
					NSString *tempFilePath = __DTXTemporaryPathForDiscardableFile();
					NSString *tempFileFilename = [fileName stringByAppendingPathComponent:tempFilePath.lastPathComponent];
					__DTXWriteFileAtPathToZip(_zip, tempFilePath, tempFileFilename);
				}
			}
		}
		
		zipClose(_zip, NULL);
	}
	
	return success;
}
