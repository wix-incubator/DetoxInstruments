//
//  DTXNetworkInspectorDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInspectorDataProvider.h"

@interface DTXNetworkInspectorDataProvider : DTXInspectorDataProvider

+ (DTXInspectorContent*)inspctorContentForData:(NSData*)data response:(NSURLResponse*)response;
+ (NSString*)fileNameBestEffortWithResponse:(NSURLResponse*)response;

@end
