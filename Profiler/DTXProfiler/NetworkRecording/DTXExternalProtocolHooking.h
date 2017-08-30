//
//  DTXExternalProtocolHooking.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol _DTXUserProtocolIsSwizzled @end

extern void (*__orig_URLProtocol_didReceiveResponse_cacheStoragePolicy)(id, SEL, NSURLProtocol*, NSURLResponse*, NSURLCacheStoragePolicy);;
extern void (*__orig_URLProtocol_didLoadData)(id, SEL, NSURLProtocol*, NSData*);
extern void (*__orig_URLProtocolDidFinishLoading)(id, SEL, NSURLProtocol*);
extern void (*__orig_URLProtocol_didFailWithError)(id, SEL, NSURLProtocol*, NSError*);
