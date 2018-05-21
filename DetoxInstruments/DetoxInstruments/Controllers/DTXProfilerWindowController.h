//
//  DTXProfilerWindowController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DTXWindowWideCopyHanler <NSObject>

@required
- (BOOL)canCopy;
- (void)copy:(id)sender targetView:(__kindof NSView*)targetView;

@end

@interface DTXProfilerWindowController : NSWindowController

@property (nonatomic, weak) __kindof NSView* targetForCopy;
@property (nonatomic, weak) id<DTXWindowWideCopyHanler> handlerForCopy;

@end
