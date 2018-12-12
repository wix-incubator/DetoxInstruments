//
//  DTXColorTryoutsWindow.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/12/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXColorTryoutsWindow.h"
#import "NSColor+UIAdditions.h"
#import "NSImage+UIAdditions.h"

@interface DTXColorTryoutsWindowController ()

@property (nonatomic, strong) NSString* userInput;
@property (nonatomic, strong) NSNumber* userInputType;
@property (nonatomic, strong) NSImage* colorImage;
@property (nonatomic, strong) NSImage* randomColorImage;

@end

@implementation DTXColorTryoutsWindowController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self _resetImages];
}

- (void)setUserInput:(NSString *)userInput
{
	[self willChangeValueForKey:@"userInput"];
	_userInput = userInput;
	[self didChangeValueForKey:@"userInput"];
	
	[self _resetImages];
}

- (void)setUserInputType:(NSNumber *)userInputType
{
	[self willChangeValueForKey:@"userInputType"];
	_userInputType = userInputType;
	[self didChangeValueForKey:@"userInputType"];
	
	[self _resetImages];
}

- (void)_resetImages
{
	self.colorImage = [NSImage imageWithColor:[NSColor uiColorWithSeed:_userInput effect:_userInputType.unsignedIntegerValue] size:NSMakeSize(1, 1)];
	self.randomColorImage = [NSImage imageWithColor:[NSColor randomColorWithSeed:_userInput] size:NSMakeSize(1, 1)];
}

@end

@implementation DTXColorTryoutsWindow

@end
