//
//  DTXInstrumentsApplication.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 21/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInstrumentsApplication.h"
#import "DTXRecordingDocument.h"

@implementation DTXInstrumentsApplication

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[self _applyAppearance];
		[NSUserDefaults.standardUserDefaults addObserver:self forKeyPath:DTXPreferencesAppearanceKey options:NSKeyValueObservingOptionNew context:NULL];
	}
	
	return self;
}

- (void)_applyAppearance
{
	NSInteger appearance = [NSUserDefaults.standardUserDefaults integerForKey:DTXPreferencesAppearanceKey];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.25;
		context.allowsImplicitAnimation = YES;
		
		switch(appearance)
		{
			case 0:
				self.appearance = nil;
				break;
			case 1:
				self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
				break;
			case 2:
				self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
				break;
		}
	}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:DTXPreferencesAppearanceKey])
	{
		[self _applyAppearance];
		
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender
{
	return [super sendAction:action to:target from:sender];
}

@end
