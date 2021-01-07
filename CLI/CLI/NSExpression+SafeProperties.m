//
//  NSExpression+SafeProperties.m
//  CLI
//
//  Created by Leo Natan (Wix) on 1/15/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "NSExpression+SafeProperties.h"
@import ObjectiveC;

@implementation NSExpression (SafeProperties)

+ (void)load
{
	Method m1 = class_getInstanceMethod(self, @selector(keyPath));
	Method m2 = class_getInstanceMethod(self, @selector(_dtx_keyPath));
	method_exchangeImplementations(m1, m2);
	
	m1 = class_getInstanceMethod(self, @selector(constantValue));
	m2 = class_getInstanceMethod(self, @selector(_dtx_constantValue));
	method_exchangeImplementations(m1, m2);
}

- (NSString *)_dtx_keyPath
{
	NSString* kp = nil;
	@try {
		kp = self._dtx_keyPath;
	}
	@catch(NSException* e) {}
	
	return kp;
}

- (id)_dtx_constantValue
{
	id v = nil;
	@try {
		v = self._dtx_constantValue;
	}
	@catch(NSException* e) {}
	
	return v;
}

@end
