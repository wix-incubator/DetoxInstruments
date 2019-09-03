//
//  DTXActionCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/2/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXActionCellView : NSTableCellView

@property (nonatomic, strong, readonly) NSStackView* buttonsStackView;
@property (nonatomic, strong, readonly) NSLayoutConstraint* buttonsStackViewConstraint;


@end
