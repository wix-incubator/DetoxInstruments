//
//  SwiftSlower.swift
//  StressTestApp
//
//  Created by Leo Natan (Wix) on 12/19/18.
//  Copyright © 2018 Wix. All rights reserved.
//

import UIKit
import os
import DTXProfiler

public class SwiftSlower: NSObject {
	@objc public class func slowOnMainThread(log: OSLog) {
		let slowFg = OSSignpostID(log: log)
		os_signpost(.begin, log: log, name: "Slow Foreground", signpostID: slowFg)
		let slowForeground = DTXProfilerMarkEventIntervalBegin("CPU Stress", "Slow Foreground", nil);
		
		let before = Date()
		
		while before.timeIntervalSinceNow > -5 {
			
		}
		
		DTXProfilerMarkEventIntervalEnd(slowForeground, .completed, nil);
		os_signpost(.end, log: log, name: "Slow Foreground", signpostID: slowFg)
	}
	
	@objc public class func slowOnBackgroundThread(log: OSLog) {
		let slowBg = OSSignpostID(log: log)
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
