//
//  DTXTextViewCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXTextViewCellView.h"
#import "NSColor+UIAdditions.h"

@interface DTXTextViewCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* contentTextField;
@property (nonatomic, strong, readwrite) IBOutlet NSBox* titleContainer;
@property (nonatomic, strong, readwrite) IBOutlet NSLayoutConstraint* titleContentConstraint;
@property (nonatomic, strong, readwrite) IBOutlet NSStackView* buttonsStackView;
@property (nonatomic, strong, readwrite) IBOutlet NSLayoutConstraint* buttonsStackViewConstraint;

@end

@implementation DTXTextViewCellView

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	[_buttonsStackView.arrangedSubviews.copy enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperview];
	}];
	
	_buttonsStackViewConstraint.constant = 0;
	_buttonsStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
}

//- (NSView *)hitTest:(NSPoint)aPoint
//{
//	return self.contentTextField.selectable ? [super hitTest:aPoint] : nil;
//}

@end
