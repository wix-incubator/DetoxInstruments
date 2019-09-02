//
//  DTXInstrumentsUtils.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/1/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTXInstrumentsUtils : NSObject

+ (NSString*)applicationVersion;
+ (NSArray<NSBundle*>*)bundlesForObjectModel;
//🙈🙉🙊
+ (BOOL)isUnsupportedVersion;

@end
