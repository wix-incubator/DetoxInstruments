//
//  DTXStackTraceCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXStackTraceCellView.h"

@interface DTXStackTraceCellView () <NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView* _stackTraceTableView;
}

@end

@implementation DTXStackTraceCellView

+ (CGFloat)heightForStackFrame
{
	return 13;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_stackTraceTableView.dataSource = self;
	_stackTraceTableView.delegate = self;
	if (@available(macOS 10.13, *)) {
		_stackTraceTableView.usesAutomaticRowHeights = NO;
	}
}

- (void)setStackFrames:(NSArray<NSAttributedString *> *)stackFrames
{
	_stackFrames = stackFrames;
	
	[_stackTraceTableView reloadData];
	[self invalidateIntrinsicContentSize];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
	return _stackFrames.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView* cellView = [tableView makeViewWithIdentifier:@"StackFrameCell" owner:nil];
	
	cellView.textField.attributedStringValue = _stackFrames[row];
	cellView.textField.allowsDefaultTighteningForTruncation = NO;
	cellView.toolTip = [_stackFrames[row] string];
	
	return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return DTXStackTraceCellView.heightForStackFrame;
}

@end
