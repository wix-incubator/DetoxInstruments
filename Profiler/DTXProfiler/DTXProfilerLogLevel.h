//
//  DTXProfilerLogLevel.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 8/25/20.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#ifndef DTXProfilerLogLevel_h
#define DTXProfilerLogLevel_h

/**
 The log level at which the entry was generated.
 */
typedef NS_ENUM(uint8_t, DTXProfilerLogLevel) {
	/**
	 The log level was never specified.
	 */
	DTXProfilerLogLevelUndefined,
	/**
	 A log level that captures diagnostic information.
	 */
	DTXProfilerLogLevelDebug = 0x2,
	/**
	 The log level that captures additional information.
	 */
	DTXProfilerLogLevelInfo = 0x01,
	/**
	 The log level that captures notifications.
	 */
	DTXProfilerLogLevelNotice = 0x00,
	/**
	 The log level that captures errors.
	 */
	DTXProfilerLogLevelError = 0x10,
	/**
	 The log level that captures fault information.
	 */
	DTXProfilerLogLevelFault = 0x11,
};

#endif /* DTXProfilerLogLevel_h */
