//
//  DTXRPCookiesEditor.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/3/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXCookiesEditorViewController.h"
#import "DTXKeyValueEditorViewController.h"

@interface DTXRPCookiesEditor : DTXKeyValueEditorViewController

@property (nonatomic, strong) NSDictionary<NSString*, NSString*>* cookies;

@end
