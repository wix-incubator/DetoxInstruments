//
//  DTXDetailDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <LNInterpolation/LNInterpolation.h>
#import "DTXDetailDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXSampleGroupProxy.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXPlotController.h"
#import "DTXFilteredDataProvider.h"
#import "NSView+UIAdditions.h"
#import "DTXSampleAggregatorProxy.h"

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

@interface DTXDetailDataProvider () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end

@implementation DTXDetailDataProvider
{
	DTXRecordingDocument* _document;
	DTXSampleContainerProxy* _rootGroupProxy;
	NSArray<DTXColumnInformation*>* _columns;
	
	BOOL _ignoresSelections;
	
	DTXFilteredDataProvider* _filteredDataProvider;
}

@synthesize delegate = _delegate;

+ (Class)inspectorDataProviderClass
{
	return nil;
}

- (instancetype)initWithDocument:(DTXRecordingDocument*)document plotController:(id<DTXPlotController>)plotController
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
	
	if(_managedOutlineView == nil)
	{
		return;
	}
	
	NSTableColumn* timestampColumn = [_managedOutlineView tableColumnWithIdentifier:@"DTXTimestampColumn"];
	timestampColumn.hidden = self.showsTimestampColumn == NO;
	
	_columns = self.columns;
	
	[_columns enumerateObjectsUsingBlock:^(DTXColumnInformation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
		column.title = obj.title;
		
		if(idx == _columns.count - 1 && obj.automaticallyGrowsWithTable)
		{
			column.resizingMask = NSTableColumnAutoresizingMask;
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

	timestampColumn.title = _document.documentState > DTXRecordingDocumentStateNew ? NSLocalizedString(@"Time", @"") : @"";
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_documentStateDidChangeNotification:) name:DTXRecordingDocumentStateDidChangeNotification object:self.document];
	
	[self setupContainerProxies];
	
	if(_document.documentState == DTXRecordingDocumentStateLiveRecording)
	{
		[_managedOutlineView scrollToBottom];
	}
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	if(_filteredDataProvider != nil)
	{
		return;
	}
	
	[self setupContainerProxies];
}

- (void)setupContainerProxies
{
	if(_document.documentState < DTXRecordingDocumentStateLiveRecording)
	{
		return;
	}
	
	_rootGroupProxy = self.rootSampleContainerProxy;
	[_rootGroupProxy reloadData];
	
	_managedOutlineView.intercellSpacing = NSMakeSize(15, 1);
	
	_managedOutlineView.headerView = self.showsHeaderView ? [NSTableHeaderView new] : nil;
	
	_managedOutlineView.delegate = self;
	_managedOutlineView.dataSource = self;
	
//	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
}

- (DTXSampleContainerProxy*)rootSampleContainerProxy
{
	return [[DTXSampleGroupProxy alloc] initWithSampleGroup:_document.recording.rootSampleGroup sampleTypes:self.sampleTypes outlineView:_managedOutlineView];
}

- (BOOL)showsHeaderView
{
	return YES && _document.documentState > DTXRecordingDocumentStateNew;
}

- (BOOL)showsTimestampColumn
{
	return YES;
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
	DTXSampleContainerProxy* proxy = _rootGroupProxy;
	if([item isKindOfClass:[DTXSampleContainerProxy class]])
	{
		proxy = item;
	}

	return [proxy samplesCount];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return @"";
}

- (NSColor*)textColorForItem:(id)item
{
	return NSColor.labelColor;
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
	DTXSampleContainerProxy* currentGroup = _rootGroupProxy;
	if([item isKindOfClass:[DTXSampleContainerProxy class]])
	{
		currentGroup = item;
	}
	
	id child = [currentGroup sampleAtIndex:index];
	if([child isKindOfClass:DTXSampleContainerProxy.class])
	{
		[child reloadData];
	}
	
	return child;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [item isKindOfClass:[DTXTag class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[DTXSampleContainerProxy class]];
}

- (void)_updateRowView:(DTXTableRowView*)rowView withItem:(id)item
{
	if([item isKindOfClass:[DTXSampleContainerProxy class]] || [item isKindOfClass:[DTXTag class]])
	{
		rowView.backgroundColor = NSColor.controlBackgroundColor;
	}
	else
	{
		rowView.backgroundColor = [self backgroundRowColorForItem:item];
		
		BOOL hasParentGroup = [item respondsToSelector:@selector(parentGroup)];
		if([rowView.backgroundColor isEqualTo:NSColor.controlBackgroundColor] && hasParentGroup && [item parentGroup] != _document.recording.rootSampleGroup)
		{
			CGFloat fraction = MIN(0.03 + (DTXDepthOfSample(item, _document.recording.rootSampleGroup) / 30.0), 0.3);
			
			rowView.backgroundColor = [NSColor.controlBackgroundColor interpolateToValue:[NSColor colorWithRed:150.0f/255.0f green:194.0f/255.0f blue:254.0f/255.0f alpha:1.0] progress:fraction];
		}
	}
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
		cellView.textField.textColor = [item isKindOfClass:[DTXSampleContainerProxy class]] ? NSColor.labelColor : [self textColorForItem:item];
		
		[self _updateRowView:rowView withItem:item];
		
		return cellView;
	}
	
	if(self.showsTimestampColumn == NO)
	{
		[self _updateRowView:rowView withItem:item];
	}
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
	
	BOOL wantsStandardGroup = NO;
	if([item isKindOfClass:DTXSampleContainerProxy.class])
	{
		wantsStandardGroup = [item wantsStandardGroupDisplay];
	}
	
	if(wantsStandardGroup && [item isKindOfClass:DTXSampleContainerProxy.class])
	{
		cellView.textField.stringValue = ((DTXSampleContainerProxy*)item).name;
		cellView.textField.textColor = NSColor.labelColor;
	}
	else if([item isMemberOfClass:[DTXTag class]])
	{
		cellView.textField.stringValue = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Tag", @""),((DTXTag*)item).name];
		cellView.textField.textColor = NSColor.labelColor;
	}
	else
	{
		NSString* str = [self formattedStringValueForItem:item column:[tableColumn.identifier integerValue]];
		
		if(str == nil)
		{
			return nil;
		}
		
		cellView.textField.stringValue = str;
		cellView.textField.textColor = [self textColorForItem:item];
	}
	
	cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:(wantsStandardGroup || [item isMemberOfClass:DTXTag.class])];
	
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
	
	if(item == nil)
	{
		return;
	}
	
	if([item isMemberOfClass:[DTXTag class]])
	{
		[_plotController removeHighlight];
		return;
	}
	
	if(_ignoresSelections == NO)
	{
		if([item isKindOfClass:[DTXSampleContainerProxy class]] == NO)
		{
			[_plotController highlightSample:item];
		}
		else
		{
			DTXSampleContainerProxy* groupProxy = item;
			
			NSDate* groupCloseTimestamp = groupProxy.closeTimestamp ?: _document.recording.endTimestamp;
			
			CPTPlotRange* groupRange = [CPTPlotRange plotRangeWithLocation:@(groupProxy.timestamp.timeIntervalSinceReferenceDate - _document.recording.startTimestamp.timeIntervalSinceReferenceDate) length:@(groupCloseTimestamp.timeIntervalSinceReferenceDate - groupProxy.timestamp.timeIntervalSinceReferenceDate)];
			[_plotController highlightRange:groupRange];
		}
	}
	
	//These are to fix a scrolling bug in the outline view.
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[_managedOutlineView scrollRowToVisible:_managedOutlineView.selectedRow];
	});
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[_managedOutlineView scrollRowToVisible:_managedOutlineView.selectedRow];
	});
}

#pragma mark DTXDetailDataProvider

- (DTXInspectorDataProvider *)currentlySelectedInspectorItem
{
	id item = [_managedOutlineView itemAtRow:_managedOutlineView.selectedRow];
	
	if(item == nil)
	{
		return nil;
	}
	
	DTXInspectorDataProvider* idp = nil;
	if([item isKindOfClass:[DTXSampleContainerProxy class]])
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

- (NSPredicate *)predicateForFilter:(NSString *)filter
{
	NSMutableArray* predicates = [NSMutableArray new];
	
	[self.filteredAttributes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[predicates addObject:[NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", obj, filter]];
	}];
	
	return [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
}

- (void)filterSamplesWithFilter:(NSString *)filter
{
	if(filter.length == 0)
	{
		_filteredDataProvider = nil;
		[self setupContainerProxies];
		[_managedOutlineView scrollRowToVisible:0];
		return;
	}
	
	_rootGroupProxy = nil;
	
	if(_filteredDataProvider == nil)
	{
		_filteredDataProvider = [[DTXFilteredDataProvider alloc] initWithDocument:self.document managedOutlineView:_managedOutlineView sampleTypes:self.sampleTypes filteredAttributes:self.filteredAttributes];
		_managedOutlineView.dataSource = _filteredDataProvider;
	}
	
	[_filteredDataProvider filterSamplesWithPredicate:[self predicateForFilter:filter]];
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
}

@end
