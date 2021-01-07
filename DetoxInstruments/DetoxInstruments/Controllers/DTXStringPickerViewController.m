//
//  DTXStringPickerViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/25/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXStringPickerViewController.h"

@implementation DTXStringPickerViewController
{
	IBOutlet NSStackView* _stackView;
	IBOutlet NSVisualEffectView* _effectView;
	IBOutlet NSProgressIndicator* _progressIndicator;
	
	NSOrderedSet<NSString*>* _strings;
	NSMutableSet<NSString*>* _enabledStrings;
	NSArray<NSButton*>* _buttons;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self view];
	_progressIndicator.usesThreadedAnimation = YES;
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

- (IBAction)_none:(id)sender
{
	[_enabledStrings removeAllObjects];
	
	[_buttons enumerateObjectsUsingBlock:^(NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.state = NSControlStateValueOff;
	}];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate stringPickerDidChangeEnabledStrings:self];
	});
}

- (IBAction)_all:(id)sender
{
	[_enabledStrings addObjectsFromArray:_strings.array];
	
	[_buttons enumerateObjectsUsingBlock:^(NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.state = NSControlStateValueOn;
	}];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate stringPickerDidChangeEnabledStrings:self];
	});
}

- (void)setShowsLoadingIndicator:(BOOL)showsLoadingIndicator
{
	_effectView.hidden = !showsLoadingIndicator;
	if(showsLoadingIndicator)
	{
		[_progressIndicator startAnimation:nil];
	}
	else
	{
		[_progressIndicator stopAnimation:nil];
	}
}

@end
