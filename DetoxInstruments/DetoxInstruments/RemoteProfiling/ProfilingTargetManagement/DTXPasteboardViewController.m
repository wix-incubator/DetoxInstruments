//
//  DTXPasteboardViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/30/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPasteboardViewController.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSImage+UIAdditions.h"
#import "DTXNSPasteboardParser.h"

@interface DTXPasteboardViewController ()
{
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
	
	IBOutlet NSTableView* _tableView;
	DTXInspectorContentTableDataSource* _tableDataSource;
	
	IBOutlet NSTextField* _emptyPasteboardLabel;
	
	NSUndoManager* _undoManager;
}

@end

@implementation DTXPasteboardViewController

@synthesize profilingTarget=_profilingTarget;

- (NSImage *)preferenceIcon
{
	return [NSImage imageNamed:@"NSColorPickerUser"];
}

- (NSString *)preferenceIdentifier
{
	return @"Pasteboard";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Pasteboard", @"");
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_tableView.wantsLayer = YES;
	_tableView.enclosingScrollView.wantsLayer = YES;
	
	_undoManager = [NSUndoManager new];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[self.view.window makeFirstResponder:self.view];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(paste:))
	{
		return menuItem.menu.supermenu != nil;
	}
	
	if(menuItem.action == @selector(copy:) || menuItem.action == @selector(cut:))
	{
		return self.profilingTarget.pasteboardContents.count > 0;
	}
	
	if(menuItem.action == @selector(undo:))
	{
		return _undoManager.canUndo;
	}
	
	if(menuItem.action == @selector(redo:))
	{
		return _undoManager.canRedo;
	}
	
	return NO;
}

- (void)_fillItem:(DTXPasteboardItem*)item intoContent:(NSMutableArray<DTXInspectorContent*>*)content
{
	[[item.types sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]] enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXInspectorContent* pbContent = [DTXInspectorContent new];
		BOOL ignoreThisType = NO;
		
		NSMutableArray<DTXInspectorContentRow*>* contentRows = [NSMutableArray new];
		if(UTTypeConformsTo(CF(type), kUTTypeImage))
		{
			pbContent.title = [NSLocalizedString(@"Image", @"") self];
			pbContent.image = [[NSImage alloc] initWithData:[item dataForType:type]];
			pbContent.titleImage = [NSImage imageNamed:@"NSColorPickerUser"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.45 green:0.73 blue:1.00 alpha:1.0];
		}
		else if([type isEqualToString:DTXColorPasteboardType])
		{
			pbContent.title = [NSLocalizedString(@"Color", @"") self];
			pbContent.image = [NSImage imageWithColor:[item valueForType:type] size:NSMakeSize(150, 150)];
			pbContent.titleImage = [NSImage imageNamed:@"NSColorPickerWheel"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.64 green:0.61 blue:1.00 alpha:1.0];
		}
		else if(UTTypeConformsTo(CF(type), kUTTypeRTFD) || UTTypeConformsTo(CF(type), kUTTypeRTF))
		{
			pbContent.title = [NSLocalizedString(@"Rich Text", @"") self];
			pbContent.titleImage = [NSImage imageNamed:@"pasteboard-rich-text"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.00 green:0.72 blue:0.58 alpha:1.0];
			
			NSAttributedString* attr = [[NSAttributedString alloc] initWithRTF:[item dataForType:type] documentAttributes:nil];
			
			if(attr)
			{
				[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:nil attributedDescription:attr]];
			}
			else
			{
				ignoreThisType = YES;
			}
		}
		else if(UTTypeConformsTo(CF(type), kUTTypeFlatRTFD))
		{
			pbContent.title = [NSLocalizedString(@"Rich Text", @"") self];
			pbContent.titleImage = [NSImage imageNamed:@"pasteboard-rich-text"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.00 green:0.72 blue:0.58 alpha:1.0];
			
			NSAttributedString* attr = [[NSAttributedString alloc] initWithRTFD:[item dataForType:type] documentAttributes:nil];
			
			if(attr)
			{
				[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:nil attributedDescription:attr]];
			}
			else
			{
				ignoreThisType = YES;
			}
		}
		else if(UTTypeConformsTo(CF(type), kUTTypeText))
		{
			pbContent.title = [NSLocalizedString(@"Text", @"") self];
			pbContent.titleImage = [NSImage imageNamed:@"pasteboard-text"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.73 green:0.86 blue:0.35 alpha:1.0];
			
			[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:nil description:(id)[item valueForType:type]]];
		}
		else if(UTTypeConformsTo(CF(type), kUTTypeURL))
		{
			pbContent.title = [NSLocalizedString(@"Link", @"") self];
			pbContent.titleImage = [NSImage imageNamed:@"pasteboard-url"];
			pbContent.titleColor = [NSColor colorWithSRGBRed:0.56 green:0.55 blue:0.85 alpha:1.0];
			
			NSURL* URL = [item valueForType:type];
			NSAttributedString* attr = [[NSAttributedString alloc] initWithString:URL.absoluteString attributes:@{NSLinkAttributeName: URL.absoluteString, NSCursorAttributeName: NSCursor.pointingHandCursor}];
			
			[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:nil attributedDescription:attr]];
		}
		else
		{
			ignoreThisType = YES;
		}
//		else
//		{
//			pbContent.title = type;
//
//			[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:nil description:[NSString stringWithFormat:@"%@", [[item dataForType:type] description]]]];
//		}
		
		if(contentRows.count > 0)
		{
			pbContent.content = contentRows;
		}
		
		if(ignoreThisType == NO)
		{
			pbContent.titleImage.size = NSMakeSize(14, 14);
			
			[content addObject:pbContent];
		}
	}];
}

- (void)_fillMultipleItemsIntoDataSource:(DTXInspectorContentTableDataSource*)tableDataSource
{
	NSMutableArray<DTXInspectorContent*>* content = [NSMutableArray new];
	
	[self.profilingTarget.pasteboardContents enumerateObjectsUsingBlock:^(DTXPasteboardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
	{
		DTXInspectorContent* groupContent = [DTXInspectorContent new];
		groupContent.title = [NSString stringWithFormat:@"Item %@", @(idx + 1)];
		groupContent.isGroup = YES;
		[content addObject:groupContent];
		
		[self _fillItem:obj intoContent:content];
		
	}];
	
	[tableDataSource setContentArray:content animateTransition:YES];
}

- (void)_fillSingleItemIntoDataSource:(DTXInspectorContentTableDataSource*)tableDataSource
{
	NSMutableArray<DTXInspectorContent*>* content = [NSMutableArray new];
	[self _fillItem:self.profilingTarget.pasteboardContents.firstObject intoContent:content];
	[tableDataSource setContentArray:content animateTransition:YES];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	if(_tableDataSource == nil)
	{
		_tableDataSource = [DTXInspectorContentTableDataSource new];
		_tableDataSource.managedTableView = _tableView;
	}
	
	if(self.profilingTarget.pasteboardContents.count == 1)
	{
		[self _fillSingleItemIntoDataSource:_tableDataSource];
	}
	else
	{
		[self _fillMultipleItemsIntoDataSource:_tableDataSource];
	}
	
	if(self.profilingTarget.pasteboardContents.count == 0)
	{
		_emptyPasteboardLabel.animator.alphaValue = 1.0;
	}
	else
	{
		_emptyPasteboardLabel.animator.alphaValue = 0.0;
	}
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadPasteboardContents];
	[_undoManager removeAllActions];
}

- (IBAction)clear:(id)sender
{
	[self _replacePasteboardContents:@[]];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadPasteboardContents];
	[_undoManager removeAllActions];
}

- (IBAction)copy:(id)sender
{
	[DTXNSPasteboardParser setGeneralPasteboardItems:self.profilingTarget.pasteboardContents];
}

- (IBAction)cut:(id)sender
{
	[self copy:sender];
	[self _replacePasteboardContents:@[]];
}

- (IBAction)paste:(id)sender
{
//	[NSPasteboard.generalPasteboard clearContents];
//	[NSPasteboard.generalPasteboard writeObjects:@[
//												   [NSImage imageNamed:@"CPUUsage"],
//												   @"Hello Normal World",
//												   [[NSAttributedString alloc] initWithString:@"Hello Bold World" attributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:20]}],
//												   NSColor.systemRedColor,
//												   NSColor.systemGreenColor,
//												   NSColor.systemBlueColor,
//												   [NSURL URLWithString:@"http://www.ynet.co.il/"],
//												   ]];
	
	[self _replacePasteboardContents:[DTXNSPasteboardParser pasteboardItemsFromGeneralPasteboard]];
}

- (void)_replacePasteboardContents:(NSArray<DTXPasteboardItem*>*)newPasteboardItems
{
	NSArray<DTXPasteboardItem*>* oldPasteboardItems = self.profilingTarget.pasteboardContents;
	
	self.profilingTarget.pasteboardContents = newPasteboardItems;
	[self noteProfilingTargetDidLoadServiceData];
	
	[[_undoManager prepareWithInvocationTarget:self] _replacePasteboardContents:oldPasteboardItems];
}

- (IBAction)undo:(id)sender
{
	[_undoManager undo];
}

- (IBAction)redo:(id)sender
{
	[_undoManager redo];
}

@end
