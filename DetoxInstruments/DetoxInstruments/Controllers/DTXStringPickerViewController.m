//
//  DTXStringPickerViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/25/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXStringPickerViewController.h"

@implementation DTXStringPickerViewController
{
	IBOutlet NSStackView* _stackView;
	
	NSOrderedSet<NSString*>* _strings;
	NSMutableSet<NSString*>* _enabledStrings;
	NSArray<NSButton*>* _buttons;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self view];
}

- (void)setStrings:(NSOrderedSet<NSString *> *)strings
{
	[_buttons enumerateObjectsUsingBlock:^(__kindof NSButton* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[_stackView removeView:obj];
	}];

	_strings = strings.copy;
	NSMutableArray* _newButtons = [NSMutableArray new];
	[_strings enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSButton* checkBox = [NSButton checkboxWithTitle:obj target:self action:@selector(_checkBox:)];
		checkBox.controlSize = NSControlSizeSmall;
		checkBox.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
		[checkBox setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
		[checkBox setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
		[checkBox setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
		[_newButtons addObject:checkBox];
		[_stackView addArrangedSubview:checkBox];
	}];
	_buttons = _newButtons;
}

- (NSOrderedSet<NSString *> *)strings
{
	return _strings;
}

- (void)setEnabledStrings:(NSSet<NSString *> *)enabledStrings
{
	_enabledStrings = enabledStrings.mutableCopy;
	
	[_buttons enumerateObjectsUsingBlock:^(NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.state = [_enabledStrings containsObject:obj.title] ? NSControlStateValueOn : NSControlStateValueOff;
	}];
}

- (NSSet<NSString *> *)enabledStrings
{
	return _enabledStrings;
}

- (void)_checkBox:(NSButton*)button
{
	if(button.state == NSControlStateValueOn)
	{
		[_enabledStrings addObject:button.title];
	}
	else
	{
		[_enabledStrings removeObject:button.title];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate stringPickerDidChangeEnabledStrings:self];
	});
	
}

@end
