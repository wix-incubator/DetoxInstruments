//
//  DTXStackTraceCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXStackTraceFrame.h"

@interface DTXStackTraceCellView : NSTableCellView

@property (class, nonatomic, readonly) CGFloat heightForStackFrame;
@property (nonatomic, weak, readonly) NSTableView* stackTraceTableView;

@property (nonatomic, copy) NSArray<DTXStackTraceFrame*>* stackFrames;

@end
