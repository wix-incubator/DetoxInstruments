//
//  DTXUIDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXUIDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXSampleGroupProxy.h"
#import "NSFormatter+PlotFormatters.h"

const CGFloat DTXAutomaticColumnWidth = -1.0;

@implementation DTXColumnInformation

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		self.minWidth = 250;
	}
	
	return self;
}

@end

@interface DTXUIDataProvider () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end

@implementation DTXUIDataProvider
{
	DTXDocument* _document;
	DTXSampleGroupProxy* _rootGroupProxy;
	NSArray<DTXColumnInformation*>* _columns;
}

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super init];
	
	if(self)
	{
		_document = document;
	}
	
	return self;
}

- (NSArray*)_prepareSamplesForGroup:(DTXSampleGroup*)group
{
	NSArray<DTXSample*>* samples = [group samplesWithTypes:@[@(self.sampleType)] includingGroups:YES];
	
	NSMutableArray* rv = [NSMutableArray new];
	
	[samples enumerateObjectsUsingBlock:^(DTXSample * _Nonnull sample, NSUInteger idx, BOOL * _Nonnull stop) {
		if([sample isKindOfClass:[DTXSampleGroup class]])
		{
			DTXSampleGroup* sampleGroup = (id)sample;
			
			DTXSampleGroupProxy* groupProxy = [DTXSampleGroupProxy new];
			groupProxy.samples = [self _prepareSamplesForGroup:sampleGroup];
			groupProxy.name = sampleGroup.name;
			groupProxy.timestamp = sampleGroup.timestamp;
			groupProxy.closeTimestamp = sampleGroup.closeTimestamp;
			
			[rv addObject:groupProxy];
		}
		else
		{
			[rv addObject:sample];
		}
	}];
	
	return rv;
}

- (void)setManagedOutlineView:(NSOutlineView *)outlineView
{
	_managedOutlineView.delegate = nil;
	_managedOutlineView.dataSource = nil;
	
	[_managedOutlineView setOutlineTableColumn:[_managedOutlineView tableColumnWithIdentifier:@"DTXTimestampColumn"]];
	
	[_managedOutlineView.tableColumns.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(idx < 1)
		{
			return;
		}
		
		[_managedOutlineView removeTableColumn:obj];
	}];
	
	[_managedOutlineView reloadData];
	
	_managedOutlineView = outlineView;
	
	_managedOutlineView.delegate = self;
	_managedOutlineView.dataSource = self;
	
	_columns = self.columns;
	
	[_columns enumerateObjectsUsingBlock:^(DTXColumnInformation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
		column.title = obj.title;
		
		if(idx == _columns.count - 1 && obj.automaticallyGrowsWithTable)
		{
			column.resizingMask = NSTableColumnAutoresizingMask;
			__block CGFloat bestWidth = _managedOutlineView.bounds.size.width;
			[_managedOutlineView.tableColumns enumerateObjectsUsingBlock:^(NSTableColumn * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				bestWidth -= (obj.width + _managedOutlineView.intercellSpacing.width);
			}];
			column.width = bestWidth - _managedOutlineView.intercellSpacing.width;
		}
		else
		{
			column.resizingMask = NSTableColumnUserResizingMask;
			column.minWidth = obj.minWidth;
			column.width = obj.minWidth;
		}
		
		[_managedOutlineView addTableColumn:column];
		
		if(idx == 0)
		{
			_managedOutlineView.outlineTableColumn = column;
		}
	}];
	
	_rootGroupProxy = [DTXSampleGroupProxy new];
	_rootGroupProxy.samples = [self _prepareSamplesForGroup:_document.recording.rootSampleGroup];
	
	_managedOutlineView.intercellSpacing = NSMakeSize(15, 1);
	
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
	
	
	CGRect frame = _managedOutlineView.window.frame;
	frame.size.width += 1;
	frame.size.width -= 1;
	[_managedOutlineView.window setFrame:frame display:NO];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//	
//}

- (DTXSampleType)sampleType
{
	return DTXSampleTypeUnknown;
}

- (NSUInteger)outlineColumnIndex;
{
	return 0;
}

- (NSArray<DTXColumnInformation*>*)columns
{
	return @[];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	DTXSampleGroupProxy* currentGroup = _rootGroupProxy;
	if([item isKindOfClass:[DTXSampleGroup class]])
	{
		currentGroup = item;
	}
	
	return currentGroup.samples.count;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return @"";
}

- (NSColor*)textColorForItem:(id)item
{
	return NSColor.blackColor;
}

- (NSColor*)backgroundRowColorForItem:(id)item;
{
	return NSColor.whiteColor;
}

- (NSFont*)_monospacedNumbersFontForFont:(NSFont*)font bold:(BOOL)bold
{
	NSFontDescriptor* fontDescriptor = [font.fontDescriptor fontDescriptorByAddingAttributes:@{NSFontTraitsAttribute: @{NSFontWeightTrait: @(bold ? NSFontWeightBold : NSFontWeightRegular)}, NSFontFeatureSettingsAttribute: @[@{NSFontFeatureTypeIdentifierKey: @(kNumberSpacingType), NSFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]}];
	return [NSFont fontWithDescriptor:fontDescriptor size:font.pointSize];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	DTXSampleGroupProxy* currentGroup = _rootGroupProxy;
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		currentGroup = item;
	}
	
	return currentGroup.samples[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[DTXSampleGroupProxy class]];
}


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if([tableColumn.identifier isEqualToString:@"DTXTimestampColumn"])
	{
		NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXRightAlignedTextCell" owner:nil];
		NSDate* timestamp = [(DTXSample*)item timestamp];
		NSTimeInterval ti = [timestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate];
							 
		cellView.textField.stringValue = [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:NO];
		cellView.textField.textColor = [item isKindOfClass:[DTXSampleGroupProxy class]] ? NSColor.blackColor : [self textColorForItem:item];
		
		return cellView;
	}
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
	
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		cellView.textField.stringValue = ((DTXSampleGroupProxy*)item).name;
		cellView.textField.textColor = NSColor.blackColor;
	}
	else
	{
		cellView.textField.stringValue = [self formattedStringValueForItem:item column:[tableColumn.identifier integerValue]];
		cellView.textField.textColor = [self textColorForItem:item];
	}
	
	cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:[item isKindOfClass:[DTXSampleGroupProxy class]]];
	
	return cellView;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	DTXTableRowView* row = [DTXTableRowView new];
	row.item = item;
	return row;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(DTXTableRowView *)rowView forRow:(NSInteger)row
{
	if([rowView.item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		rowView.backgroundColor = NSColor.whiteColor;
		return;
	}
	
	rowView.backgroundColor = [self backgroundRowColorForItem:rowView.item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [item isKindOfClass:[DTXSampleGroupProxy class]];
}

@end
