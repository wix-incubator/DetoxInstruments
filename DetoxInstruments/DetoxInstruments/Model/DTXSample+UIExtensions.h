//
//  DTXSample+UIExtensions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSample+CoreDataClass.h"
@import AppKit;

@interface DTXSample (UIExtensions)

@property (nonatomic, copy, readonly) NSString* descriptionForUI;
@property (nonatomic, strong, readonly) NSImage* imageForUI;

- (BOOL)isKind;

@end
