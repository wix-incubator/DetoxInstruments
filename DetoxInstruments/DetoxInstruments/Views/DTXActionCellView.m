//
//  DTXActionCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/2/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXActionCellView.h"

@interface DTXActionCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSStackView* buttonsStackView;
@property (nonatomic, strong, readwrite) IBOutlet NSLayoutConstraint* buttonsStackViewConstraint;

@end

@implementation DTXActionCellView

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	[self.buttonsStackView.arrangedSubviews.copy enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperview];
	}];
	
	self.buttonsStackViewConstraint.constant = 0;
	self.buttonsStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
}

@end
