//
//  DTXWindowsSnapshotter.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 11/13/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DTXWindowsSnapshotter : NSObject

+ (NSData*)snapshotDataForApp;

@end

NS_ASSUME_NONNULL_END
