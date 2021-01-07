//
//  NSKeyedUnarchiver+QuickDecodingSecureCoding.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/13/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSKeyedUnarchiver (QuickDecodingSecureCoding)

+ (nullable id)dtx_unarchiveObjectWithData:(NSData *)data requiringSecureCoding:(BOOL)requiresSecureCoding error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
