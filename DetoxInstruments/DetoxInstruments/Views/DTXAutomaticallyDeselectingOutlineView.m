//
//  DTXAutomaticallyDeselectingOutlineView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 24/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXAutomaticallyDeselectingOutlineView.h"

@implementation DTXAutomaticallyDeselectingOutlineView

- (BOOL)resignFirstResponder
{
	[self deselectAll:nil];
	
	return [super resignFirstResponder];
}


@end
