//
//  DTXUIDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <LNInterpolation/LNInterpolation.h>
#import "DTXUIDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXSampleGroupProxy.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXPlotController.h"
#import "DTXFilteredDataProvider.h"

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
	
	BOOL _ignoresSelections;
	
	DTXFilteredDataProvider* _filteredDataProvider;
}

@synthesize delegate = _delegate;

+ (Class)inspectorDataProviderClass
{
	return nil;
}

- (instancetype)initWithDocument:(DTXDocument*)document plotController:(id<DTXPlotController>)plotController
{
	self = [super init];
	
	if(self)
	{
		_document = document;
		_plotController = plotController;
	}
	
	return self;
}

- (NSString *)displayName
{
	return self.plotController.displayName;
}

- (NSImage *)displayIcon
{
	return self.plotController.displayIcon;
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

	_managedOutlineView.tableColumns[[_managedOutlineView columnWithIdentifier:@"DTXTimestampColumn"]].title = _document.documentState > DTXDocumentStateNew ? NSLocalizedString(@"Time", @"") : @"";
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXDocumentStateDidChangeNotification object:self.document];
	
	[self _setupProxiesForGroups];
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	if(_filteredDataProvider != nil)
	{
		return;
	}
	
	[self _setupProxiesForGroups];
}

- (void)_setupProxiesForGroups
{
	if(_document.documentState < DTXDocumentStateLiveRecording)
	{
		return;
	}
	
	_rootGroupProxy = [[DTXSampleGroupProxy alloc] initWithSampleGroup:_document.recording.rootSampleGroup sampleTypes:self.sampleTypes outlineView:_managedOutlineView];
	
	_managedOutlineView.intercellSpacing = NSMakeSize(15, 1);
	
	_managedOutlineView.headerView = self.showsHeaderView ? [NSTableHeaderView new] : nil;
	
	_managedOutlineView.delegate = self;
	_managedOutlineView.dataSource = self;
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
	
	CGRect frame = _managedOutlineView.window.frame;
	frame.size.width += 1;
	frame.size.width -= 1;
	[_managedOutlineView.window setFrame:frame display:NO];
}

- (BOOL)showsHeaderView
{
	return YES && _document.documentState > DTXDocumentStateNew;
}

- (NSArray<NSNumber* /*DTXSampleType*/>* )sampleTypes
{
	return @[@(DTXSampleTypeUnknown)];
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[];
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
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		currentGroup = item;
	}

	return [currentGroup samplesCount];
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
	return nil;
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
	
	return [currentGroup sampleAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[DTXSampleGroupProxy class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	DTXTableRowView* rowView = (id)[outlineView rowViewAtRow:[outlineView rowForItem:item] makeIfNecessary:YES];
	
	if([tableColumn.identifier isEqualToString:@"DTXTimestampColumn"])
	{
		NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXRightAlignedTextCell" owner:nil];
		NSDate* timestamp = [(DTXSample*)item timestamp];
		NSTimeInterval ti = [timestamp timeIntervalSinceReferenceDate] - [_document.recording.startTimestamp timeIntervalSinceReferenceDate];
							 
		cellView.textField.stringValue = [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:NO];
		cellView.textField.textColor = [item isKindOfClass:[DTXSampleGroupProxy class]] ? NSColor.blackColor : [self textColorForItem:item];
		
		if([item isKindOfClass:[DTXSampleGroupProxy class]])
		{
			rowView.backgroundColor = NSColor.whiteColor;
		}
		else
		{
			rowView.backgroundColor = [self backgroundRowColorForItem:item];
			
			BOOL hasParentGroup = [item respondsToSelector:@selector(parentGroup)];
			if([rowView.backgroundColor isEqualTo:NSColor.whiteColor] && hasParentGroup && [item parentGroup] != _document.recording.rootSampleGroup)
			{
				CGFloat fraction = MIN(0.03 + (DTXDepthOfSample(item, _document.recording.rootSampleGroup) / 30.0), 0.3);
				
				rowView.backgroundColor = [NSColor.whiteColor interpolateToValue:[NSColor colorWithRed:150.0f/255.0f green:194.0f/255.0f blue:254.0f/255.0f alpha:1.0] progress:fraction];
			}
		}
		
		return cellView;
	}
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
	
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		cellView.textField.stringValue = ((DTXSampleGroupProxy*)item).name;
		cellView.textField.textColor = NSColor.textColor;
	}
	else if([item isMemberOfClass:[DTXTag class]])
	{
		cellView.textField.stringValue = ((DTXTag*)item).name;
		cellView.textField.textColor = NSColor.textColor;
	}
	else
	{
		cellView.textField.stringValue = [self formattedStringValueForItem:item column:[tableColumn.identifier integerValue]];
		cellView.textField.textColor = [self textColorForItem:item];
	}
	
	cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:([item isKindOfClass:[DTXSampleGroupProxy class]] || [item isMemberOfClass:[DTXTag class]])];
	
	return cellView;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	DTXTableRowView* rowView = [DTXTableRowView new];
	rowView.item = item;
	
	return rowView;
}

NSUInteger DTXDepthOfSample(DTXSample* sample, DTXSampleGroup* rootSampleGroup)
{
	if(sample.parentGroup == nil || sample.parentGroup == rootSampleGroup)
	{
		return 0;
	}
	
	return MIN(1 + DTXDepthOfSample(sample.parentGroup, rootSampleGroup), 20);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [item isKindOfClass:[DTXSampleGroupProxy class]] || [item isMemberOfClass:[DTXTag class]];
}

- (void)selectSample:(DTXSample*)sample
{
	NSInteger idx = [_managedOutlineView rowForItem:sample];
	_ignoresSelections = YES;
	[_managedOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
	[_managedOutlineView scrollRowToVisible:idx];
	_ignoresSelections = NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	DTXInspectorDataProvider* idp = self.currentlySelectedInspectorItem;
	[self.delegate dataProvider:self didSelectInspectorItem:idp];
	
	id item = [_managedOutlineView itemAtRow:_managedOutlineView.selectedRow];
	
	if([item isMemberOfClass:[DTXTag class]])
	{
		[_plotController removeHighlight];
		return;
	}
	
	if(_ignoresSelections == NO)
	{
		if([item isKindOfClass:[DTXSampleGroupProxy class]] == NO)
		{
			[_plotController highlightSample:item];
		}
		else
		{
			DTXSampleGroupProxy* groupProxy = item;
			
			NSDate* groupCloseTimestamp = groupProxy.closeTimestamp ?: _document.recording.endTimestamp;
			
			CPTPlotRange* groupRange = [CPTPlotRange plotRangeWithLocation:@(groupProxy.timestamp.timeIntervalSinceReferenceDate - _document.recording.startTimestamp.timeIntervalSinceReferenceDate) length:@(groupCloseTimestamp.timeIntervalSinceReferenceDate - groupProxy.timestamp.timeIntervalSinceReferenceDate)];
			[_plotController highlightRange:groupRange];
		}
	}
}

#pragma mark DTXUIDataProvider

- (DTXInspectorDataProvider *)currentlySelectedInspectorItem
{
	id item = [_managedOutlineView itemAtRow:_managedOutlineView.selectedRow];
	
	if(item == nil)
	{
		return nil;
	}
	
	DTXInspectorDataProvider* idp = nil;
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		idp = [[DTXGroupInspectorDataProvider alloc] initWithSample:item document:_document];
	}
	else if([item isMemberOfClass:[DTXTag class]])
	{
		idp = [[DTXTagInspectorDataProvider alloc] initWithSample:item document:_document];
	}
	else
	{
		idp = [[[self.class inspectorDataProviderClass] alloc] initWithSample:item document:_document];
	}
	
	return idp;
}

#pragma mark DTXUIDataFiltering

- (BOOL)supportsDataFiltering
{
	return NO;
}

- (void)filterSamplesWithFilter:(NSString *)filter
{
	if(filter.length == 0)
	{
		_filteredDataProvider = nil;
		[self _setupProxiesForGroups];
		return;
	}
	
	_rootGroupProxy = nil;
	
	if(_filteredDataProvider == nil)
	{
		_filteredDataProvider = [[DTXFilteredDataProvider alloc] initWithDocument:self.document managedOutlineView:_managedOutlineView sampleTypes:self.sampleTypes filteredAttributes:self.filteredAttributes];
		_managedOutlineView.dataSource = _filteredDataProvider;
	}
	
	[_filteredDataProvider filterSamplesWithFilter:filter];
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
}

@end
