//
//  DTXProfiler-Private.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 19/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#if __has_include("DTXProfiler.h")
#import "DTXProfiler.h"
#endif

@class DTXRecording, DTXSampleGroup, DTXPerformanceSample, DTXAdvancedPerformanceSample;
@class DTXThreadInfo, DTXReactNativePeroformanceSample, DTXNetworkSample, DTXLogSample, DTXTag;

@protocol _DTXProfilerStoryListener <NSObject>

- (void)createRecording:(DTXRecording*)recording;
- (void)updateRecording:(DTXRecording*)recording stopRecording:(BOOL)stopRecording;
- (void)pushSampleGroup:(DTXSampleGroup*)sampleGroup isRootGroup:(BOOL)root;
- (void)popSampleGroup:(DTXSampleGroup*)sampleGroup;
- (void)createdOrUpdatedThreadInfo:(DTXThreadInfo*)threadInfo;
- (void)addPerformanceSample:(__kindof DTXPerformanceSample*)perfrmanceSample;
- (void)addRNPerformanceSample:(DTXReactNativePeroformanceSample *)rnPerfrmanceSample;
- (void)startRequestWithNetworkSample:(DTXNetworkSample*)networkSample;
- (void)finishWithResponseForNetworkSample:(DTXNetworkSample*)networkSample;
- (void)addLogSample:(DTXLogSample*)logSample;
- (void)addTag:(DTXTag*)tag;

@end

#if __has_include("DTXProfiler.h")
@interface DTXProfiler ()

@property (nonatomic, weak, getter=_profilerStoryListener, setter=_setInternalDelegate:) id<_DTXProfilerStoryListener> _profilerStoryListener;

@end
#endif
