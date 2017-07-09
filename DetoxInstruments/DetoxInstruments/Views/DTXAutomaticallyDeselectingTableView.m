//
//  DTXAutomaticallyDeselectingTableView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXAutomaticallyDeselectingTableView.h"

@implementation DTXAutomaticallyDeselectingTableView

- (BOOL)resignFirstResponder
{
	[self deselectAll:nil];
	
	return [super resignFirstResponder];
}

@end

