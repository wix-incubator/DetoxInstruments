//
//  DTXSelectingArrayController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/28/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXTableEditingArrayController.h"

@implementation DTXTableEditingArrayController

- (void)add:(id)sender
{
	[super add:sender];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if(_tableView.currentEditor)
		{
			[_tableView endEditing:_tableView.currentEditor];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[_tableView editColumn:0 row:[self.arrangedObjects count] - 1 withEvent:nil select:YES];
		});
	});
}

@end
