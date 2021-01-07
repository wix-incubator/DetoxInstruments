//
//  DTXAutomaticallyDeselectingTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXAutomaticallyDeselectingTableView.h"

@implementation DTXAutomaticallyDeselectingTableView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	if (@available(macOS 11.0, *))
	{
		self.style = NSTableViewStyleFullWidth;
	}
}

- (BOOL)resignFirstResponder
{
	[self deselectAll:nil];
	
	return [super resignFirstResponder];
}

@end

