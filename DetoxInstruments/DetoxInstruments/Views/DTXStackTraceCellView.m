//
//  DTXStackTraceCellView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXStackTraceCellView.h"
#import "DTXTableRowView.h"
#import "NSImage+UIAdditions.h"
#import "DTXTwoLabelsCellView.h"

@interface DTXStackTraceCellView () <NSTableViewDataSource, NSTableViewDelegate>
{
	NSMenu* _rightClickMenu;
}

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
	
	_rightClickMenu = _stackTraceTableView.menu;
}

- (void)setStackFrames:(NSArray<DTXStackTraceFrame *> *)stackFrames
{
	_stackFrames = stackFrames;
	
	[_stackTraceTableView reloadData];
	[_stackTraceTableView.enclosingScrollView invalidateIntrinsicContentSize];
}

- (void)setSelectionDisabled:(BOOL)selectionDisabled
{
	_selectionDisabled = selectionDisabled;
	
	_stackTraceTableView.menu = _selectionDisabled == YES ? nil : _rightClickMenu;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	return _selectionDisabled == NO;
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
	DTXTwoLabelsCellView* cellView = [tableView makeViewWithIdentifier:@"StackFrameCell" owner:nil];
	
	cellView.textField.attributedStringValue = _stackFrames[row].stackFrameText;
	cellView.textField.allowsDefaultTighteningForTruncation = NO;
	cellView.detailTextField.attributedStringValue = _stackFrames[row].stackFrameDetailText;
	__block NSImage* image = _stackFrames[row].stackFrameIcon;
	NSColor* tintColor = _stackFrames[row].imageTintColor;
	if(tintColor != nil)
	{
		image = [image imageTintedWithColor:tintColor];
	}
	cellView.imageView.image = image;
	[cellView.imageView.layer setNeedsDisplay];
	cellView.toolTip = _stackFrames[row].fullStackFrameText;
	
	return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return DTXStackTraceCellView.heightForStackFrame;
}

@end
