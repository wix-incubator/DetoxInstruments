//
//  DTXTextViewCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXTextViewCellView : NSTableCellView

@property (nonatomic, strong, readonly) NSTextField* contentTextField;
@property (nonatomic, strong, readonly) NSLayoutConstraint* titleContentConstraint;
@property (nonatomic, strong, readonly) NSBox* titleContainer;
@property (nonatomic, strong, readonly) NSStackView* buttonsStackView;
@property (nonatomic, strong, readonly) NSLayoutConstraint* buttonsStackViewConstraint;

@end
