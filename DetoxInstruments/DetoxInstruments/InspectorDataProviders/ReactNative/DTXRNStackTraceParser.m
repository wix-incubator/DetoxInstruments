//
//  DTXRNStackTraceParser.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/29/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRNStackTraceParser.h"

@implementation DTXRNStackTraceParser

+ (NSString*)stackTraceFrameStringForObject:(id)obj includeFullFormat:(BOOL)fullFormat
{
	NSString* stackTraceFrame = nil;
	
	if([obj isKindOfClass:[NSString class]] == YES)
	{
		stackTraceFrame = obj;
		
		//		\#(\d+) (.*)\(\) at (.*?)(:(\d+))?$
		NSRegularExpression* expr = [NSRegularExpression regularExpressionWithPattern:@"\\#(\\d+) (.*)\\(\\) at (.*?)(:(\\d+))?$" options:0 error:NULL];
		
		NSTextCheckingResult* match = [expr matchesInString:stackTraceFrame options:0 range:NSMakeRange(0, stackTraceFrame.length)].firstObject;
		
		if(match.numberOfRanges == 6)
		{
			NSString* funcName = [obj substringWithRange:[match rangeAtIndex:2]];
			NSString* codeURLString = [obj substringWithRange:[match rangeAtIndex:3]];
			
			NSNumber* line;
			__unused NSNumber* column = @0;
			
			if([match rangeAtIndex:4].location != NSNotFound)
			{
				NSInteger lineNumber = [obj substringWithRange:[match rangeAtIndex:5]].integerValue;
				
				line = @(lineNumber);
			}
			
			NSString* sourceFileName = codeURLString;
			
			NSString* symbolName = funcName;
			
			stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", symbolName, fullFormat ? sourceFileName : [sourceFileName lastPathComponent], line != nil ? [NSString stringWithFormat:@":%@", line] : @""];
		}
	}
	else if([obj isKindOfClass:[NSDictionary class]] == YES)
	{
		stackTraceFrame = [NSString stringWithFormat:@"%@() at %@%@", obj[@"symbolName"], fullFormat ? obj[@"sourceFileName"] : [obj[@"sourceFileName"] lastPathComponent], obj[@"line"] ? [NSString stringWithFormat:@":%@", obj[@"line"]] : @""];
	}
	
	if([stackTraceFrame stringByTrimmingWhiteSpace].length == 0)
	{
		stackTraceFrame = @"<native>";
	}
	
	return stackTraceFrame;
}

	
@end
