//
//  DTXStackTraceCopyDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInspectorDataProvider.h"

@interface DTXStackTraceCopyDataProvider : DTXInspectorDataProvider

- (NSArray*)arrayForStackTrace;
- (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat;
- (DTXInspectorContent*)inspectorContentForStackTrace;
- (NSImage*)imageForObject:(id)obj;

@end
