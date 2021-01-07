//
//  DTXSegmentedControl.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/08/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXSegmentedControl.h"

@interface NSView ()

- (void)_updateContentState;

@end

@interface NSSegmentedCell ()

- (void)_setIndexOfHilightedSegment:(long long)arg1;
- (void)_selectHighlightedSegment;

@end

@implementation DTXSegmentedControl

- (void)setSelected:(BOOL)selected forSegment:(NSInteger)segment
{
	[super setSelected:selected forSegment:segment];

	//Fix a bug in High Sierra where images are not highlighted propertly.
	[self.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if([obj respondsToSelector:@selector(_updateContentState)])
		{
			[obj _updateContentState];
		}
	}];
}

@end
