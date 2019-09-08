//
//  main.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import ObjectiveC;

@interface NSStoryboard (XcodePoop) @end

@implementation NSStoryboard (XcodePoop)

- (NSBundle*)_bundle
{
	return [NSBundle mainBundle];
}

@end

int main(int argc, const char * argv[])
{
	if([NSUserName() isEqualToString:@"lnatan"] || [NSUserName() isEqualToString:@"leonatan"])
	{
		[NSUserDefaults.standardUserDefaults registerDefaults:@{@"NSUseRemoteSavePanel": @NO}];
	}
	
	return NSApplicationMain(argc, argv);
}
