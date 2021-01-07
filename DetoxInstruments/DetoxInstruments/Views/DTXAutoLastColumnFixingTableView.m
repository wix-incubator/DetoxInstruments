//
//  DTXAutoLastColumnFixingTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan on 10/25/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXAutoLastColumnFixingTableView.h"

@implementation DTXAutoLastColumnFixingTableView

- (void)layout
{
	[super layout];
	
	if((self.tableColumns.lastObject.resizingMask & NSTableColumnAutoresizingMask) == NSTableColumnAutoresizingMask)
	{
		[self sizeLastColumnToFit];
	}
}

@end
