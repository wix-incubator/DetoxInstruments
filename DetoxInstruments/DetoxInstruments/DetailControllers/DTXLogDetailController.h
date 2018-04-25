//
//  DTXLogDetailController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXDetailController.h"
#import "DTXDocument.h"

@interface DTXLogDetailController : DTXDetailController

- (void)loadProviderWithDocument:(DTXDocument*)document;
- (void)scrollToTimestamp:(NSDate*)timestamp;

@end
