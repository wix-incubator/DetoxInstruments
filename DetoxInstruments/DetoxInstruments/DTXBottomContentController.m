//
//  DTXBottomContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXBottomContentController.h"
#import "DTXDocument.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"

@interface DTXBottomContentController ()
{
	__weak IBOutlet NSOutlineView *_outlineView;
}

@end

@implementation DTXBottomContentController

- (void)setManagingDataProvider:(DTXUIDataProvider *)managingDataProvider
{
	_managingDataProvider.managedOutlineView = nil;
	_managingDataProvider = managingDataProvider;
	_managingDataProvider.managedOutlineView = _outlineView;
}

@end
