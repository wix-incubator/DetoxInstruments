//
//  DTXInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInspectorDataProvider.h"

@implementation DTXInspectorDataProvider

- (instancetype)initWithSample:(__kindof DTXSample *)sample document:(DTXDocument *)document
{
	self = [super init];
	
	if(self)
	{
		_sample = sample;
		_document = document;
	}
	
	return self;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	return nil;
}

- (BOOL)canCopy
{
	return NO;
}

- (BOOL)canSaveAs
{
	return NO;
}

- (IBAction)copy:(id)sender targetView:(__kindof NSView *)targetView
{
	//NOOP
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	//NOOP
}

@end
