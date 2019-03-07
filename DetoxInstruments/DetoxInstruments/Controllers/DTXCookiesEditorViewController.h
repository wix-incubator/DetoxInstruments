//
//  DTXCookiesEditorViewController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/3/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import LNPropertyListEditor;

@interface DTXCookiesEditorViewController : NSViewController

+ (NSArray<NSDictionary<NSString*, id>*>*)cookiesByFillingMissingFieldsOfCookies:(NSArray<NSDictionary<NSString*, id>*>*)cookies;

@property (nonatomic, strong) IBOutlet LNPropertyListEditor* plistEditor;
@property (nonatomic, strong) NSArray<NSDictionary<NSString*, id>*>* cookies;

@end
