//
//  DTXLogDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXLogDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXTextViewCellView.h"

@interface DTXLogDataProvider() <NSTableViewDataSource, NSTableViewDelegate>
{
	NSArray<NSDictionary<NSString*, NSString*>*>* _logEntries;
}

@end

@implementation DTXLogDataProvider

- (instancetype)initWithDocument:(DTXDocument*)document managedTableView:(NSTableView*)tableView
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_managedTableView = tableView;
		
		NSFetchRequest* fr = [DTXLogSample fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.resultType = NSDictionaryResultType;
		
		fr.propertiesToFetch = @[@"timestamp", @"line"];
		
		_logEntries = [_document.recording.managedObjectContext executeFetchRequest:fr error:NULL];
		
		_managedTableView.dataSource = self;
		_managedTableView.delegate = self;
		
		[_managedTableView reloadData];
	}
	
	return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _logEntries.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [DTXTableRowView new];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXTextViewCellView* cell = [tableView makeViewWithIdentifier:@"DTXLogEntryCell" owner:nil];
	cell.contentTextField.stringValue = [_logEntries[row][@"line"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	return cell;
}

- (CGFloat)_displayHeightForString:(NSString*)string width:(CGFloat)width
{
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
	
	return [attr boundingRectWithSize:NSMakeSize(width, 0) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return [self _displayHeightForString:[_logEntries[row][@"line"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] width:CGFLOAT_MAX];
}

@end
