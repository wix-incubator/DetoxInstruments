//
//  NSString+Hashing.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/30/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Hashing)

@property (nonatomic, copy, readonly) NSData* sufficientHash;

@end
