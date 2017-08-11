//
//  DTXStackTraceFrame.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 10/08/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTXStackTraceFrame : NSObject

@property (nonatomic, copy) NSAttributedString* stackFrameText;
@property (nonatomic, copy) NSImage* stackFrameIcon;

@end
