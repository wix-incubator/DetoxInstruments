//
//  DTXRPSnippetExporter.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DTXRPSnippetExporter <NSObject>

+ (NSString*)snippetWithRequest:(NSURLRequest*)request;

@end
