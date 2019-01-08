//
//  DTXRNJSCSourceMapsSupport.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 02/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//


#import <Foundation/Foundation.h>

#if __has_include(<DTXSourceMaps/DTXSourceMaps.h>)
#import <DTXSourceMaps/DTXSourceMaps.h>
#else
#import "DTXSourceMapsParser.h"
#endif

#if DTX_PROFILER
#import "DTXCustomJSCSupport.h"

extern NSArray* DTXRNSymbolicateJSCBacktrace(NSArray<NSString*>* backtrace, BOOL* currentStackTraceSymbolicated);
extern void DTXRNGetCurrentWorkingSourceMapsData(void (^completion)(NSData*));
extern void DTXInitializeSourceMapsSupport(DTXJSCWrapper* wrapper);
#else
extern NSArray* DTXRNSymbolicateJSCBacktrace(DTXSourceMapsParser* parser, NSArray<NSString*>* backtrace, BOOL* currentStackTraceSymbolicated);
#endif
