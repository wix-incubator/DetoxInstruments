//
//  DTXTimelineMouseView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXTimelineIndicatorView : NSView

@property (nonatomic) BOOL displaysIndicator;
@property (nonatomic) CGFloat indicatorOffset;
@property (nonatomic, weak) NSTableView* tableView;

@end
