//
//  DTXRNJSCSourceMapsSupport.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 02/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "DTXSourceMapsParser.h"

extern NSArray* DTXRNSymbolicateJSCBacktrace(NSArray<NSString*>* backtrace, BOOL* currentStackTraceSymbolicated);

