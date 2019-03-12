//
//  DTXKeyValueEditorViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/4/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXKeyValueEditorViewController.h"

@interface DTXKeyValueEditorViewController ()

@end

@implementation DTXKeyValueEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_plistEditor.typeColumnHidden = YES;
	_plistEditor.delegate = self;
}

#pragma mark LNPropertyListEditorDelegate

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditTypeOfNode:(LNPropertyListNode*)node
{
	return NO;
}


@end
