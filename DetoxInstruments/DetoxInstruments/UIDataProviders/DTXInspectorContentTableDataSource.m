//
//  DTXContentAwareTableDataSource.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 14/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXInspectorContentTableDataSource.h"
#import "DTXTextViewCellView.h"
@import QuartzCore;

@implementation DTXInspectorContent @end

@interface DTXInspectorContentTableDataSource () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation DTXInspectorContentTableDataSource

- (void)setManagedTableView:(NSTableView *)managedTableView
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	//Cleanup
	_managedTableView.dataSource = nil;
	_managedTableView.delegate = nil;
	[_managedTableView reloadData];
	
	_managedTableView = managedTableView;
	
	_managedTableView.wantsLayer = YES;
	_managedTableView.layer = [_managedTableView makeBackingLayer];
	
	_managedTableView.dataSource = self;
	_managedTableView.delegate = self;
	[_managedTableView reloadData];
	
//	[_managedTableView.superview.superview setPostsBoundsChangedNotifications:YES];
//	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_managedTableViewBoundsDidChange) name:NSViewBoundsDidChangeNotification object:_managedTableView.superview.superview];
//
//	[_managedTableView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
	[CATransaction commit];
}

- (void)setContentArray:(NSArray<DTXInspectorContent *> *)contentArray
{
	_contentArray = [contentArray copy];
	[_managedTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _contentArray.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	DTXInspectorContent* content = _contentArray[row];
	
	__kindof NSTableCellView* cell = [tableView makeViewWithIdentifier:content.image ? @"DTXImageViewCellView" : @"DTXTextViewCellView" owner:nil];
	
	if(content.image == nil)
	{
		[cell textView].string = content.content;
		[cell textView].font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
	}
	
	cell.textField.stringValue = content.title ?: @"Title";
	cell.imageView.image = content.image;
	
	return cell;
}

- (CGFloat)_displayHeightForString:(NSString*)string width:(CGFloat)width
{
	NSAttributedString* attr = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
	
	return [attr boundingRectWithSize:NSMakeSize(width, 0) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	DTXInspectorContent* content = _contentArray[row];
	
	CGFloat top = 3 + 14 + 5;
	CGFloat bottom = 3;
	CGFloat leading = 15;
	CGFloat trailing = 3;
	
	if(content.image)
	{
		CGFloat availableWidth = tableView.bounds.size.width - leading - trailing;
		CGFloat scale = 1.0;
		if(availableWidth < content.image.size.width)
		{
			scale = availableWidth / content.image.size.width;
		}
		
		return top + content.image.size.height * scale + bottom;
	}
	else
	{
		return top + [self _displayHeightForString:content.content width:tableView.bounds.size.width - leading - trailing] + bottom;
	}
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//
//}
//
//- (void)_managedTableViewBoundsDidChange
//{
//	NSMutableIndexSet* is = [NSMutableIndexSet new];
//
//	[_contentArray enumerateObjectsUsingBlock:^(DTXInspectorContent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//		if(obj.image != nil)
//		{
//			[is addIndex:idx];
//		}
//	}];
//
//	[_managedTableView noteHeightOfRowsWithIndexesChanged:is];
//}

@end
