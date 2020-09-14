//
//  DTXKeyDownIgnoringTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/15/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXKeyDownIgnoringTableView.h"

@implementation DTXKeyDownIgnoringTableView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if (@available(macOS 11.0, *))
	{
		self.style = NSTableViewStyleFullWidth;
	}
}

- (void)keyDown:(NSEvent *)event
{
	
}

@end
