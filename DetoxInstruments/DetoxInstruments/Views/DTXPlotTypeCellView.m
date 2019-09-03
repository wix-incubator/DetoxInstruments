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
@property (nonatomic, strong, readwrite) IBOutlet NSPopUpButton* settingsButton;

@end

@implementation DTXPlotTypeCellView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[_settingsButton sendActionOn:NSEventMaskLeftMouseDown];
#if PROFILER_PREVIEW_EXTENSION
	self.textField.cell.lineBreakMode = NSLineBreakByWordWrapping;
	self.textField.allowsDefaultTighteningForTruncation = YES;
#endif
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.settingsButton.highlighted = self.bottomLegendTextField.highlighted = self.topLegendTextField.highlighted = backgroundStyle == NSBackgroundStyleDark;
	[self.settingsButton.cell setBackgroundStyle:backgroundStyle];
}


@end
