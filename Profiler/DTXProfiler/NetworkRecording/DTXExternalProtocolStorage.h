//
//  DTXExternalProtocolStorage.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 29/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _DTXExternalProtocolStorage : NSObject

+ (void)setEnabled:(BOOL)enabled;

+ (void)addProtocolInstance:(NSURLProtocol*)protocolInstance;
+ (void)setResponse:(NSURLResponse*)response forProtocolInstance:(NSURLProtocol*)protocolInstance;
+ (void)appendLoadedData:(NSData*)data forProtocolInstance:(NSURLProtocol*)protocolInstance;
+ (void)setError:(NSError*)error forProtocolInstance:(NSURLProtocol*)protocolInstance;
+ (void)getResponse:(out NSURLResponse**)response data:(out NSData**)data error:(out NSError**)error forProtocolInstance:(NSURLProtocol*)protocolInstance;

@end
