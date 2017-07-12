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
	NSArray<NSDictionary<NSString*, id>*>* _logEntries;
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
	cell.contentTextField.allowsDefaultTighteningForTruncation = NO;
	if(NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 13)
	{
		cell.contentTextField.usesSingleLineMode = YES;
		cell.contentTextField.lineBreakMode = NSLineBreakByTruncatingTail;
	}
	
	return cell;
}

- (void)scrollToTimestamp:(NSDate*)timestamp
{
	NSUInteger idx = [_logEntries indexOfObject:@{@"timestamp": timestamp} inSortedRange:NSMakeRange(0, _logEntries.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSDictionary<NSString*, NSString*>* _Nonnull obj1, NSDictionary<NSString*, NSString*>*  _Nonnull obj2) {
		return [obj1[@"timestamp"] compare:obj2[@"timestamp"]];
	}];
	
	if(idx > 0)
	{
		idx -= 1;
	}
	
	if(idx < _logEntries.count)
	{
		[_managedTableView scrollRowToVisible:idx];
		
		[_managedTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		//Do it a second time to "fix" potential scroll inaccuracy due to automatic cell height
		[_managedTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	}
}

@end
