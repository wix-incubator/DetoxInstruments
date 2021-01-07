//
//  DTXLiveLogWindowController+DocumentationGeneration.m
//  DetoxInstruments
//
//  Created by Leo Natan on 10/25/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#if DEBUG

#import "DTXLiveLogWindowController+DocumentationGeneration.h"

@interface NSTitlebarAccessoryViewController ()

@property (nonatomic) BOOL errorsOnly;
@property (nonatomic) BOOL appOnly;
@property (nonatomic) BOOL excludeApple;

@end

@implementation DTXLiveLogWindowController (DocumentationGeneration)

- (void)_selectAny
{
	NSTitlebarAccessoryViewController* accessory = self.window.titlebarAccessoryViewControllers.firstObject;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			NSTableView* tv = [self.window.contentViewController valueForKeyPath:@"tableView"];
			[tv selectRowIndexes:[NSIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
			
			[tv scrollRowToVisible:0];
			
			[tv.enclosingScrollView setHasHorizontalScroller:YES];
			tv.enclosingScrollView.horizontalScroller.alphaValue = 0.0;
			[tv.enclosingScrollView setHasVerticalScroller:YES];
			tv.enclosingScrollView.verticalScroller.alphaValue = 0.0;
			
			accessory.errorsOnly = NO;
			accessory.appOnly = NO;
			accessory.excludeApple = NO;
		});
	});
}

@end

#endif
