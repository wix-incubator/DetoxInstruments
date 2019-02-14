//
//  DTXSignpostAdditionalInfoEndProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 2/5/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostAdditionalInfoEndProxy.h"

@implementation DTXSignpostAdditionalInfoEndProxy

@dynamic additionalInfoEnd;

- (instancetype)initWithSignpostSample:(DTXSignpostSample *)sample
{
	self = [super init];
	
	if(self)
	{
		_sample = sample;
	}
	
	return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [self respondsToSelector:aSelector] || [_sample respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _sample;
}

@end
