//
//  NSString+FileNames.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FileNames)

@property (nonatomic, copy, readonly) NSString* stringBySanitizingForFileName;

@end
