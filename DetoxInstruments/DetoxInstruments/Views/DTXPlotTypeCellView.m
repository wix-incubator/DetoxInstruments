//
//  DTXPlotTypeCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPlotTypeCellView.h"

@interface DTXPlotTypeCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSImageView* secondaryImageView;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* topLegendTextField;
@property (nonatomic, strong, readwrite) IBOutlet NSTextField* bottomLegendTextField;
@property (nonatomic, strong, readwrite) IBOutlet NSButton* settingsButton;

@end

@implementation DTXPlotTypeCellView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[_settingsButton sendActionOn:NSEventMaskLeftMouseDown];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.settingsButton.highlighted = self.bottomLegendTextField.highlighted = self.topLegendTextField.highlighted = backgroundStyle == NSBackgroundStyleDark;
	[self.settingsButton.cell setBackgroundStyle:backgroundStyle];
}

//- (void)setFrameSize:(NSSize)newSize
//{
//	newSize.height = NSHeight(self.superview.frame) - 1;
//	
//	[super setFrameSize:newSize];
//}

@end
