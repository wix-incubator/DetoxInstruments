//
//  DTXTableRowView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXTableRowView : NSTableRowView

@property (nonatomic, strong) id item;

@property (nonatomic, strong, readonly) NSColor* selectionColor;
@property (nonatomic, strong) NSColor* userNotifyColor;
- (void)setUserNotifyTooltip:(NSString*)tooltip;

@end
