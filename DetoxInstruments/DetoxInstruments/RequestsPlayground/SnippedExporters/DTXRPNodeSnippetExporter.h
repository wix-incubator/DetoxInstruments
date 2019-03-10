//
//  DTXRPNodeSnippetExporter.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXRPSnippetExporter.h"

@interface DTXRPNodeSnippetExporter : NSObject <DTXRPSnippetExporter>

+ (NSString*)snippetWithRequest:(NSURLRequest*)request;

@end
