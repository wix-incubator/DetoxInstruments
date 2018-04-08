//
//  DTXZipper.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL DTXWriteZipFileWithContents(NSURL* zipURL, NSURL* contentsURL);
extern BOOL DTXWriteZipFileWithFile(NSURL* zipURL, NSURL* fileURL);
extern BOOL DTXWriteZipFileWithDirectoryContents(NSURL* zipURL, NSURL* directoryURL);
