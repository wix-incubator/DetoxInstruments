//
//  DTXPasteboardViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/30/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPasteboardViewController.h"
#import "DTXInspectorContentTableDataSource.h"

@interface DTXPasteboardViewController ()
{
	IBOutlet NSButton* _helpButton;
	IBOutlet NSButton* _refreshButton;
	
	IBOutlet NSTableView* _tableView;
	DTXInspectorContentTableDataSource* _tableDataSource;
}

@end

@implementation DTXPasteboardViewController

@synthesize profilingTarget=_profilingTarget;

- (NSImage *)preferenceIcon
{
	return [NSImage imageNamed:@"NSMediaBrowserIcon"];
}

- (NSString *)preferenceIdentifier
{
	return @"Pasteboard";
}

- (NSString *)preferenceTitle
{
	return NSLocalizedString(@"Pasteboard", @"");
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[self.view.window makeFirstResponder:self.view];
}

- (void)noteProfilingTargetDidLoadServiceData
{
	_tableDataSource = [DTXInspectorContentTableDataSource new];
	
	NSMutableArray<DTXInspectorContent*>* content = [NSMutableArray new];
	
	[self.profilingTarget.pasteboardContents enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		[obj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			DTXInspectorContent* pbContent = [DTXInspectorContent new];
			pbContent.title = [NSString stringWithFormat:@"%@", key];
			if(UTTypeConformsTo((__bridge CFTypeRef)key, kUTTypeImage))
			{
				pbContent.image = [NSImage imageNamed:@"Bottom"];
//				pbContent.image = [[NSImage alloc] initWithData:obj];
			}
			else
			{
				NSMutableArray<DTXInspectorContentRow*>* contentRows = [NSMutableArray new];
				[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Type", @"") description:key]];
				[contentRows addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data", @"") description:[NSString stringWithFormat:@"%@", [obj description]]]];
				pbContent.content = contentRows;
			}
			[content addObject:pbContent];
		}];
	}];
	
	_tableDataSource.contentArray = content;
	_tableDataSource.managedTableView = _tableView;
}

- (void)setProfilingTarget:(DTXRemoteProfilingTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	if(profilingTarget == nil)
	{
		return;
	}
	
	[self.profilingTarget loadPasteboardContents];
}

- (IBAction)refresh:(id)sender
{
	[self.profilingTarget loadPasteboardContents];
}


@end
