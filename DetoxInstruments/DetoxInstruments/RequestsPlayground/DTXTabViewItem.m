//
//  DTXTabViewItem.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXTabViewItem.h"

@interface NSTabViewItem ()

- (void)_setTabEnabled:(BOOL)tabEnabled;

@end

@implementation DTXTabViewItem

- (instancetype)initWithIdentifier:(id)identifier
{
	self = [super initWithIdentifier:identifier];
	
	if(self)
	{
		[self _dtx_commonInit];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[self _dtx_commonInit];
	
	[super awakeFromNib];
}

- (void)_dtx_commonInit
{
	_enabled = YES;
}

- (void)setEnabled:(BOOL)enabled
{
	_enabled = enabled;
	
	[self _setTabEnabled:_enabled];
}

@end
