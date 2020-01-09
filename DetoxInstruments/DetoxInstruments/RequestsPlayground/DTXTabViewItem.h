//
//  DTXTabViewItem.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXTabViewItem : NSTabViewItem

@property (nonatomic, getter=isEnabled) IBInspectable BOOL enabled;

@end
