//
//  DTXBrokenRNFlipper.m
//  DTXProfiler
//
//  Created by Leo Natan on 11/12/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXBrokenRNFlipper.h"

@implementation DTXBrokenRNFlipper

+ (void)load
{
	//Disable broken RN Flopper until it is fixed:
	//	https://github.com/facebook/flipper/issues/1674
	@autoreleasepool
	{
		Class cls = NSClassFromString(@"FlipperClient");
		if(cls != nil)
		{
			SEL sel = NSSelectorFromString(@"sharedClient");
			Method m = class_getClassMethod(cls, sel);
			
			if(m != NULL)
			{
				method_setImplementation(m, imp_implementationWithBlock(^id(id _self) {
					return nil;
				}));
			}
		}
		
		NSArray* flapperPlugins = @[@"FlipperKitLayoutPlugin", @"FKUserDefaultsPlugin", @"FlipperKitReactPlugin", @"FlipperKitNetworkPlugin", ];
		[flapperPlugins enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			Class cls = objc_getMetaClass(obj.UTF8String);
			if(cls != nil)
			{
				class_addMethod(cls, @selector(alloc), imp_implementationWithBlock(^id(id _self) {
					return nil;
				}), "@@:");
			}
		}];
	}
}

@end
