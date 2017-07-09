//
//  DTXInstrumentsApplication.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 21/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInstrumentsApplication.h"

@interface NSView (LayerForAll) @end

@implementation NSView (LayerForAll)

- (BOOL)wantsLayer
{
	return YES;
}

@end

@implementation DTXInstrumentsApplication

- (instancetype)init
{
	return [super init];
}

- (id)targetForAction:(SEL)action to:(id)target from:(id)sender
{
	//Disable new tab button
	if(action == @selector(newWindowForTab:))
	{
		return nil;
	}
	
	if(action == @selector(duplicateDocument:))
	{
		return nil;
	}
	
	if(action == @selector(saveDocument:))
	{
		return nil;
	}
	
	if(action == @selector(saveDocumentAs:))
	{
		return nil;
	}
	
	return [super targetForAction:action to:target from:sender];
}

@end
