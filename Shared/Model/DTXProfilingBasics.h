//
//  DTXRemoteProfilingBasics.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 23/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

@class NSEntityDescription;

#if __has_include("DTXEventStatusPrivate.h")
	#import "DTXEventStatusPrivate.h"
#endif

typedef NS_ENUM(NSUInteger, DTXRemoteProfilingCommandType) {
	DTXRemoteProfilingCommandTypePing = 0,
	DTXRemoteProfilingCommandTypeGetDeviceInfo = 1,
	DTXRemoteProfilingCommandTypeStartProfilingWithConfiguration = 2,
	DTXRemoteProfilingCommandTypeStartLaunchProfilingWithConfiguration = 20,
	DTXRemoteProfilingCommandTypeStartLocalProfilingWithConfiguration = 21,
	DTXRemoteProfilingCommandTypeAddTag = 3,
	DTXRemoteProfilingCommandTypePushGroup __deprecated = 4,
	DTXRemoteProfilingCommandTypePopGroup __deprecated = 5,
	DTXRemoteProfilingCommandTypeProfilingStoryEvent = 6,
	DTXRemoteProfilingCommandTypeStopProfiling = 7,
	
	DTXRemoteProfilingCommandTypeGetContainerContents = 8,
	DTXRemoteProfilingCommandTypeDownloadContainer = 9,
	DTXRemoteProfilingCommandTypeDeleteContainerIten = 10,
	DTXRemoteProfilingCommandTypePutContainerItem = 11,
	
	DTXRemoteProfilingCommandTypeGetUserDefaults = 12,
	DTXRemoteProfilingCommandTypeChangeUserDefaultsItem = 13,
	
	DTXRemoteProfilingCommandTypeGetCookies = 14,
	DTXRemoteProfilingCommandTypeSetCookies = 15,
	
	DTXRemoteProfilingCommandTypeGetPasteboard = 16,
	DTXRemoteProfilingCommandTypeSetPasteboard = 17,
	
	DTXRemoteProfilingCommandTypeCaptureViewHierarchy = 18,
	
	DTXRemoteProfilingCommandTypeLoadScreenSnapshot = 19,
};

typedef NS_ENUM(NSUInteger, DTXUserDefaultsChangeType) {
	DTXUserDefaultsChangeTypeInsert,
	DTXUserDefaultsChangeTypeDelete,
	DTXUserDefaultsChangeTypeMove,
	DTXUserDefaultsChangeTypeUpdate
};

@class DTXRecording, DTXPerformanceSample;
@class DTXThreadInfo, DTXReactNativePeroformanceSample, DTXNetworkSample, DTXLogSample, DTXTag;
@class DTXSignpostSample, DTXReactNativeDataSample;

@protocol DTXProfilerStoryListener <NSObject>

- (void)createRecording:(DTXRecording*)recording;
- (void)updateRecording:(DTXRecording*)recording stopRecording:(BOOL)stopRecording;
- (void)createdOrUpdatedThreadInfo:(DTXThreadInfo*)threadInfo;
- (void)addPerformanceSample:(__kindof DTXPerformanceSample*)perfrmanceSample;
- (void)addRNPerformanceSample:(DTXReactNativePeroformanceSample *)rnPerfrmanceSample;
- (void)startRequestWithNetworkSample:(DTXNetworkSample*)networkSample;
- (void)finishWithResponseForNetworkSample:(DTXNetworkSample*)networkSample;
- (void)addRNBridgeDataSample:(DTXReactNativeDataSample*)rbBridgeDataSample;
- (void)addLogSample:(DTXLogSample*)logSample;
- (void)addTagSample:(DTXTag*)tag;
- (void)markEventIntervalBegin:(DTXSignpostSample*)signpostSample;
- (void)markEventIntervalEnd:(DTXSignpostSample*)signpostSample;
- (void)markEvent:(DTXSignpostSample*)signpostSample;

@end

@protocol DTXProfilerStoryDecoder <NSObject>

- (void)performBlock:(void(^)(void))block;
- (void)performBlockAndWait:(void(^)(void))block;

- (void)willDecodeStoryEvent;
- (void)didDecodeStoryEvent;

- (void)setSourceMapsData:(NSDictionary*)sourceMapsData;

- (void)createRecording:(NSDictionary*)recording entityDescription:(NSEntityDescription*)entityDescription;
- (void)updateRecording:(NSDictionary*)recording stopRecording:(NSNumber*)stopRecording entityDescription:(NSEntityDescription*)entityDescription;
- (void)createdOrUpdatedThreadInfo:(NSDictionary*)threadInfo entityDescription:(NSEntityDescription*)entityDescription;
- (void)addPerformanceSample:(NSDictionary*)perfrmanceSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)addRNPerformanceSample:(NSDictionary *)rnPerfrmanceSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)startRequestWithNetworkSample:(NSDictionary*)networkSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)finishWithResponseForNetworkSample:(NSDictionary*)networkSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)addRNBridgeDataSample:(NSDictionary*)rbBridgeDataSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)addLogSample:(NSDictionary*)logSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)addTagSample:(NSDictionary*)tag entityDescription:(NSEntityDescription*)entityDescription;
- (void)markEventIntervalBegin:(NSDictionary*)signpostSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)markEventIntervalEnd:(NSDictionary*)signpostSample entityDescription:(NSEntityDescription*)entityDescription;
- (void)markEvent:(NSDictionary*)signpostSample entityDescription:(NSEntityDescription*)entityDescription;


@end
