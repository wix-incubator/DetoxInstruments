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

@end

@implementation DTXPlotTypeCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[super setBackgroundStyle:backgroundStyle];
	
	self.bottomLegendTextField.highlighted = self.topLegendTextField.highlighted = backgroundStyle == NSBackgroundStyleDark;
}

//- (void)setFrameSize:(NSSize)newSize
//{
//	newSize.height = NSHeight(self.superview.frame) - 1;
//	
//	[super setFrameSize:newSize];
//}

@end
