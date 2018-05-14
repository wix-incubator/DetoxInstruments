//
//  DTXTextViewCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXTextViewCellView.h"
#import "NSColor+UIAdditions.h"

@interface DTXTextViewCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSTextField* contentTextField;
@property (nonatomic, strong, readwrite) IBOutlet NSBox* titleContainer;
@property (nonatomic, strong, readwrite) IBOutlet NSLayoutConstraint* titleContentConstraint;

@end

@implementation DTXTextViewCellView

//- (NSView *)hitTest:(NSPoint)aPoint
//{
//	return self.contentTextField.selectable ? [super hitTest:aPoint] : nil;
//}

@end
