//
//  SwiftSlower.swift
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 12/19/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

import UIKit
import os
import DTXProfiler

public class SwiftSlower: NSObject {
	private static var log = OSLog(subsystem: "com.LeoNatan.StressTestApp", category: "CPU Stress")
	
	@objc public class func slowOnMainThread() {
		let slowFg = OSSignpostID(log: SwiftSlower.log)
		os_signpost(.begin, log: log, name: "Slow Foreground", signpostID: slowFg)
		let slowForeground = DTXProfilerMarkEventIntervalBegin("CPU Stress", "Slow Foreground", nil);
		
		let before = Date()
		
		while before.timeIntervalSinceNow > -5 {
			
		}
		
		DTXProfilerMarkEventIntervalEnd(slowForeground, .completed, nil);
		os_signpost(.end, log: log, name: "Slow Foreground", signpostID: slowFg)
	}
	
	@objc public class func slowOnBackgroundThread() {
		let slowBg = OSSignpostID(log: SwiftSlower.log)
		os_signpost(.begin, log: log, name: "Slow Background", signpostID: slowBg)
		
		let slowBackground = DTXProfilerMarkEventIntervalBegin("CPU Stress", "Slow Background", nil);
		
		let before = Date()
		
		DispatchQueue.global(qos: .userInitiated).async {
			while before.timeIntervalSinceNow > -10 {
			}
			
			DTXProfilerMarkEventIntervalEnd(slowBackground, .completed, nil);
			os_signpost(.end, log: log, name: "Slow Background", signpostID: slowBg)
		}
	}
}
