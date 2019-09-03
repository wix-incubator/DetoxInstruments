//
//  DTXViewCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 21/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXActionCellView.h"

@interface DTXViewCellView : DTXActionCellView

@property (nonatomic, strong, readonly) NSView* contentView;

@end
