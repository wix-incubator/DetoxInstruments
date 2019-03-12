//
//  DTXRequestsPlaygroundWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DTXNetworkSample;

@interface DTXRequestsPlaygroundWindowController : NSWindowController

- (void)loadRequestDetailsFromNetworkSample:(DTXNetworkSample*)networkSample;

@end
