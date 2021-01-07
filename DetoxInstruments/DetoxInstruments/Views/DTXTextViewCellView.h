//
//  DTXTextViewCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXActionCellView.h"

@interface DTXTextViewCellView : DTXActionCellView

@property (nonatomic, strong, readonly) NSTextField* contentTextField;
@property (nonatomic, strong, readonly) NSLayoutConstraint* titleContentConstraint;
@property (nonatomic, strong, readonly) NSBox* titleContainer;

@end
