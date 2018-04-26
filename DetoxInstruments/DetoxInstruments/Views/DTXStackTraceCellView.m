//
//  DTXStackTraceCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXStackTraceCellView.h"
#import "DTXTableRowView.h"

@interface DTXStackTraceCellView () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak, readwrite) IBOutlet NSTableView* stackTraceTableView;

@end

@implementation DTXStackTraceCellView

+ (CGFloat)heightForStackFrame
{
	return 17;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_stackTraceTableView.intercellSpacing = NSZeroSize;
	_stackTraceTableView.dataSource = self;
	_stackTraceTableView.delegate = self;
	_stackTraceTableView.usesAutomaticRowHeights = NO;
}

- (void)setStackFrames:(NSArray<DTXStackTraceFrame *> *)stackFrames
{
	_stackFrames = stackFrames;
	
	[_stackTraceTableView reloadData];
	[_stackTraceTableView.enclosingScrollView invalidateIntrinsicContentSize];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
	return _stackFrames.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [DTXTableRowView new];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView* cellView = [tableView makeViewWithIdentifier:@"StackFrameCell" owner:nil];
	
	cellView.textField.attributedStringValue = _stackFrames[row].stackFrameText;
	cellView.textField.allowsDefaultTighteningForTruncation = NO;
	cellView.imageView.image = _stackFrames[row].stackFrameIcon;
	cellView.toolTip = _stackFrames[row].fullStackFrameText;
	
	return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return DTXStackTraceCellView.heightForStackFrame;
}

@end
