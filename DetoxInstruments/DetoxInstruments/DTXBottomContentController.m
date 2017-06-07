//
//  DTXBottomContentController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXBottomContentController.h"
#import "DTXDocument.h"
#import "DTXSampleGroup+CoreDataClass.h"
#import "DTXInstrumentsModelUIExtensions.h"

@interface DTXBottomContentController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	__weak IBOutlet NSOutlineView *_outlineView;
	DTXDocument* _currentDocument;
}

@end

@implementation DTXBottomContentController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	_currentDocument = (id)_outlineView.window.windowController.document;
	
	[_outlineView reloadData];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	DTXSampleGroup* currentGroup = _currentDocument.recording.rootSampleGroup;
	if([item isKindOfClass:[DTXSampleGroup class]])
	{
		currentGroup = item;
	}
	
	return currentGroup.samples.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	DTXSampleGroup* currentGroup = _currentDocument.recording.rootSampleGroup;
	if([item isKindOfClass:[DTXSampleGroup class]])
	{
		currentGroup = item;
	}
	
	return currentGroup.samples[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[DTXSampleGroup class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXCellView" owner:nil];
	
	cellView.imageView.image = [item imageForUI];
	cellView.textField.stringValue = [item descriptionForUI];
	
	return cellView;
}

@end
