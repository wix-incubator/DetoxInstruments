//
//  DTXMenuPathContro.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 09/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DTXMenuPathControlDelegate <NSPathControlDelegate>

@required
- (NSMenu *)pathControl:(NSPathControl *)pathControl menuForCell:(NSPathComponentCell *)cell;

@end

@interface DTXMenuPathControl : NSPathControl

@property (weak) id <DTXMenuPathControlDelegate> delegate;

@end
