//
//  DTXPlotControllerPickerCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/12/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPlotControllerPickerCellView.h"

@implementation DTXPlotControllerPickerCellView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	_plotControllerEnabled = YES;
	
	self.imageView.wantsLayer = YES;
	self.imageView.layer.borderWidth = 2.0;
	self.imageView.layer.borderColor = NSColor.whiteColor.CGColor;
	self.imageView.layer.cornerRadius = 15;
	self.imageView.layer.masksToBounds = YES;
}

- (void)setPlotController:(id<DTXPlotController>)plotController
{
	_plotController = plotController;
	
	[self.imageView setImage:plotController.displayIcon];
	
	NSMutableAttributedString* asv = [NSMutableAttributedString new];
	[asv appendAttributedString:[[NSAttributedString alloc] initWithString:plotController.displayName attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:NSFont.smallSystemFontSize], NSForegroundColorAttributeName: NSColor.labelColor}]];
	[asv appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" - %@", plotController.toolTip] attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize], NSForegroundColorAttributeName: NSColor.labelColor}]];
	
	self.textField.attributedStringValue = asv;
}

- (void)setPlotControllerEnabled:(BOOL)plotControllerEnabled
{
	_plotControllerEnabled = plotControllerEnabled;
	
	self.animator.alphaValue = _plotControllerEnabled ? 1.0 : 0.3;
}

@end
