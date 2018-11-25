//
//  main.m
//  DTXProfilerShimTest
//
//  Created by Leo Natan (Wix) on 11/25/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTXProfiler.h"

int main(int argc, char * argv[]) {
	DTXMutableProfilingConfiguration* config = [DTXMutableProfilingConfiguration defaultProfilingConfiguration];
	[config setRecordingFileURL:nil];
	[config setRecordNetwork:NO];
	
	DTXProfiler* profiler = [[DTXProfiler alloc] init];
	[profiler startProfilingWithConfiguration:config];
	
	DTXEventIdentifier x = DTXProfilerMarkEventIntervalBegin(@"1", @"2", @"3");
	DTXProfilerMarkEventIntervalEnd(x, 0, @"4");
	DTXProfilerMarkEvent(@"5", @"6", 7, @"8");
	
	DTXProfilerAddTag(@"10");
	DTXProfilerAddLogLine(@"11");
	DTXProfilerAddLogLineWithObjects(@"12", @[@"13"]);
	
	[profiler stopProfilingWithCompletionHandler:^(NSError * _Nullable error) {
	}];
}
