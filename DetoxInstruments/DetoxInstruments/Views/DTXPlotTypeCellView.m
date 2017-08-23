//
//  DTXPlotTypeCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXPlotTypeCellView.h"

@interface DTXPlotTypeCellView ()

@property (nonatomic, strong, readwrite) IBOutlet NSImageView* secondaryImageView;

@end

@implementation DTXPlotTypeCellView

- (BOOL)canDrawConcurrently
{
	return YES;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.secondaryImageView.wantsLayer = YES;
    self.secondaryImageView.layer.backgroundColor = NSColor.blackColor.CGColor;
	self.secondaryImageView.layer.cornerRadius = 10.35;
}

@end
