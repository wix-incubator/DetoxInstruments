//
//  DTXRequestDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/13/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXRecordingDocument.h"

@interface DTXRequestDocument : NSDocument

- (void)loadRequestDetailsFromNetworkSample:(DTXNetworkSample*)networkSample document:(DTXRecordingDocument*)document;

@end
