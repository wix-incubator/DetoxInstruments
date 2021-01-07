//
//  DTXLiveLogStreamer.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 8/27/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, DTXOSLogEntryLogLevel) {
	DTXOSLogEntryLogLevelUndefined,
	DTXOSLogEntryLogLevelDebug = 0x2,
	DTXOSLogEntryLogLevelInfo = 0x01,
	DTXOSLogEntryLogLevelNotice = 0x00,
	DTXOSLogEntryLogLevelError = 0x10,
	DTXOSLogEntryLogLevelFault = 0x11,
};

@interface DTXLiveLogStreamer : NSObject

@property (nonatomic) BOOL processOnly;
@property (nonatomic) BOOL allowsDebug;
@property (nonatomic) BOOL allowsInfo;
@property (nonatomic) BOOL allowsApple;

- (void)startLoggingWithHandler:(void (^)(BOOL isFromProcess, const char *proc_imagepath, BOOL isFromApple, NSDate * _Nonnull, DTXOSLogEntryLogLevel, NSString * _Nonnull, NSString * _Nonnull, NSString * _Nonnull))handler;

@end

NS_ASSUME_NONNULL_END
