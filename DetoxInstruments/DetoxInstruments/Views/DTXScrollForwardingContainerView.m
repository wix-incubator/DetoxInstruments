//
//  DTXScrollForwardingContainerView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/4/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXScrollForwardingContainerView.h"

@implementation DTXScrollForwardingContainerView
{
	NSScrollView* _cachedScrollView;
}

static NSScrollView* _firstScrollDescendant(NSArray<NSView*>* subviews)
{
	for (__kindof NSView* view in subviews)
	{
		if([view isKindOfClass:NSScrollView.class])
		{
			return view;
		}
		
		return _firstScrollDescendant(view.subviews);
	}
	
	return nil;
}

- (void)scrollWheel:(NSEvent *)event
{
	if(_cachedScrollView == nil)
	{
		_cachedScrollView = _firstScrollDescendant(self.subviews);
	}
	
	[_cachedScrollView scrollWheel:event];
}

@end
