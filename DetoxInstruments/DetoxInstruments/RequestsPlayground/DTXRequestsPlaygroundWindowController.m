//
//  DTXRequestsPlaygroundWindowController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRequestsPlaygroundWindowController.h"
#import "DTXRequestsPlaygroundController.h"

@interface DTXRequestsPlaygroundWindowController ()

@end

@implementation DTXRequestsPlaygroundWindowController

- (void)loadRequestDetailsFromNetworkSample:(DTXNetworkSample*)networkSample
{
	[(DTXRequestsPlaygroundController*)self.contentViewController loadRequestDetailsFromNetworkSample:networkSample];
}

@end
