//
//  DTXZipper.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSURL* DTXTempZipURL(void);

extern BOOL DTXWriteZipFileWithURL(NSURL* zipURL, NSURL* contentsURL);
extern BOOL DTXWriteZipFileWithFileURL(NSURL* zipURL, NSURL* fileURL);
extern BOOL DTXWriteZipFileWithDirectoryURL(NSURL* zipURL, NSURL* directoryURL);

extern BOOL DTXWriteZipFileWithURLArray(NSURL* zipURL, NSArray<NSURL*>* contentsURLs);
