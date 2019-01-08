//
//  DTXDetailDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <LNInterpolation/LNInterpolation.h>
#import "DTXDetailDataProvider.h"
#import "DTXTableRowView.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXEntitySampleContainerProxy.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXPlotController.h"
#import "DTXFilteredDataProvider.h"
#import "NSView+UIAdditions.h"
#import "DTXSampleAggregatorProxy.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXSignpostProtocol.h"

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
	NSArray<DTXColumnInformation*>* _columns;
	
	BOOL _ignoresSelections;
	
	DTXFilteredDataProvider* _filteredDataProvider;
}

@synthesize delegate = _delegate;

+ (Class)inspectorDataProviderClass
{
	return nil;
}

- (Class)dataExporterClass
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

+ (NSString *)defaultDetailDataProviderIdentifier
{
	return @"Samples";
}

- (NSString *)identifier
{
	return DTXDetailDataProvider.defaultDetailDataProviderIdentifier;
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Samples", @"");;
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"samples"];
	image.size = NSMakeSize(16, 16);
	
	return image;
}

- (void)setManagedOutlineView:(NSOutlineView *)outlineView
{
	_managedOutlineView.delegate = nil;
	_managedOutlineView.dataSource = nil;
	
	[_managedOutlineView setOutlineTableColumn:[_managedOutlineView tableColumnWithIdentifier:@"DTXTimestampColumn"]];
	
	[_managedOutlineView.tableColumns.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(idx <= self.outlineColumnIndex)
		{
			return;
		}
		
		[_managedOutlineView removeTableColumn:obj];
	}];
	
	[_managedOutlineView reloadData];
	
	_managedOutlineView = outlineView;
	
	if(_managedOutlineView == nil)
	{
		[_rootGroupProxy unloadData];
		
		return;
	}
	
	[self setupContainerProxiesReloadOutline:NO];
	
	NSTableColumn* timestampColumn = [_managedOutlineView tableColumnWithIdentifier:@"DTXTimestampColumn"];
	timestampColumn.hidden = self.showsTimestampColumn == NO;
	
	timestampColumn.sortDescriptorPrototype = self.supportsSorting ? [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES] : nil;
	
//	_managedOutlineView.outlineTableColumn = timestampColumn;
	
	_columns = self.columns;
	
	[_columns enumerateObjectsUsingBlock:^(DTXColumnInformation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
		column.title = obj.title;
		
		if(self.supportsSorting)
		{
			column.sortDescriptorPrototype = obj.sortDescriptor;
		}
		
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
	
	_managedOutlineView.intercellSpacing = NSMakeSize(15, 1);
	_managedOutlineView.headerView = self.showsHeaderView ? [NSTableHeaderView new] : nil;
	
	_managedOutlineView.delegate = self;
	_managedOutlineView.dataSource = self;
	
	[_managedOutlineView scrollRowToVisible:0];
	
	if(_document.documentState == DTXRecordingDocumentStateLiveRecording)
	{
		[_managedOutlineView scrollToBottom];
	}
	
	//This fixes an NSTableView layout issue where the last column does not take the full space of the table view.
	CGRect frame = _managedOutlineView.enclosingScrollView.frame;
	frame.size.width += 1;
	_managedOutlineView.enclosingScrollView.frame = frame;
	[_managedOutlineView setNeedsLayout:YES];
	[_managedOutlineView layoutSubtreeIfNeeded];
	frame.size.width -= 1;
	_managedOutlineView.enclosingScrollView.frame = frame;
	[_managedOutlineView setNeedsLayout:YES];
	[_managedOutlineView layoutSubtreeIfNeeded];
}

- (void)_documentStateDidChangeNotification:(NSNotification*)note
{
	if(_filteredDataProvider != nil)
	{
		return;
	}
	
	[self setupContainerProxiesReloadOutline:YES];
}

- (void)setupContainerProxiesReloadOutline:(BOOL)reloadOutline
{
	if(_document.documentState < DTXRecordingDocumentStateLiveRecording)
	{
		return;
	}
	
	_rootGroupProxy = self.rootSampleContainerProxy;
	[_rootGroupProxy reloadData];
	
	if(reloadOutline)
	{
		_managedOutlineView.delegate = self;
		_managedOutlineView.dataSource = self;
	}
}

- (DTXSampleContainerProxy*)rootSampleContainerProxy
{
	return [[DTXEntitySampleContainerProxy alloc] initWithOutlineView:_managedOutlineView managedObjectContext:_document.firstRecording.managedObjectContext sampleClass:self.sampleClass];
}

- (BOOL)showsHeaderView
{
	return YES && _document.documentState > DTXRecordingDocumentStateNew;
}

- (BOOL)showsTimestampColumn
{
	return YES;
}

- (Class)sampleClass
{
	return nil;
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[];
}

- (NSUInteger)outlineColumnIndex;
{
	return 1;
}

- (NSArray<DTXColumnInformation*>*)columns
{
	return @[];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	id<DTXSampleGroupProxy> proxy = _rootGroupProxy;
	if(item != nil)
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

- (NSString*)statusTooltipforItem:(id)item
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
	id<DTXSampleGroupProxy> currentGroup = _rootGroupProxy;
	if(item != nil)
	{
		currentGroup = item;
	}
	
	id child = [currentGroup sampleAtIndex:index];
	
	if([child conformsToProtocol:@protocol(DTXSampleGroupDynamicDataLoadingProxy)])
	{
		[child reloadData];
	}
	
	return child;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return NO;
	
//	return [item isKindOfClass:DTXTag.class] || ([item isKindOfClass:DTXSampleGroupProxy.class] && [item wantsStandardGroupDisplay]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item conformsToProtocol:@protocol(DTXSampleGroupProxy)] && [item isExpandable];
}

- (void)_updateRowView:(DTXTableRowView*)rowView withItem:(id)item
{
	[rowView setUserNotifyTooltip:nil];
	
	if([item conformsToProtocol:@protocol(DTXSampleGroupProxy)] || [item isKindOfClass:[DTXTag class]])
	{
		rowView.userNotifyColor = NSColor.controlBackgroundColor;
	}
	else
	{
		rowView.userNotifyColor = [self backgroundRowColorForItem:item];
		[rowView setUserNotifyTooltip:[self statusTooltipforItem:item]];
	}
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if([tableColumn.identifier isEqualToString:@"DTXSpacingColumn"])
	{
		return nil;
	}
	
	DTXTableRowView* rowView = (id)[outlineView rowViewAtRow:[outlineView rowForItem:item] makeIfNecessary:YES];
	
	if([tableColumn.identifier isEqualToString:@"DTXTimestampColumn"])
	{
		NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
		NSDate* timestamp = [(DTXSample*)item timestamp];
		NSTimeInterval ti = [timestamp timeIntervalSinceReferenceDate] - [_document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
							 
		cellView.textField.stringValue = [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:NO];
		cellView.textField.textColor = [item conformsToProtocol:@protocol(DTXSampleGroupProxy)] ? NSColor.labelColor : [self textColorForItem:item];
		
		[self _updateRowView:rowView withItem:item];
		
		return cellView;
	}
	
	if(self.showsTimestampColumn == NO)
	{
		[self _updateRowView:rowView withItem:item];
	}
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
	
	BOOL wantsStandardGroup = NO;
	if([item conformsToProtocol:@protocol(DTXSampleGroupProxy)])
	{
		wantsStandardGroup = [item wantsStandardGroupDisplay];
	}
	
	if([item isMemberOfClass:[DTXTag class]])
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

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
	[self.rootGroupProxy sortWithSortDescriptors:outlineView.sortDescriptors];
}

- (BOOL)_findSample:(DTXSample*)sample inContainerProxy:(DTXSampleContainerProxy*)containerProxy traversalChain:(NSMutableArray*)chain
{
	[chain addObject:containerProxy];
	BOOL found = NO;
	
	if([containerProxy isDataLoaded] == NO)
	{
		[containerProxy reloadData];
	}
	
	for (NSUInteger idx = 0; idx < [containerProxy samplesCount]; idx ++)
	{
		id sampleOrProxy = [containerProxy sampleAtIndex:idx];
		if(sampleOrProxy == sample)
		{
			[chain addObject:sample];
			found = YES;
			break;
		}
		
		if([sampleOrProxy isKindOfClass:DTXSampleContainerProxy.class])
		{
			found = [self _findSample:sample inContainerProxy:sampleOrProxy traversalChain:chain];
			
			if(found)
			{
				break;
			}
		}
	}
	
	if(found == NO)
	{
		[chain removeObject:containerProxy];
	}
	
	return found;
}

- (void)selectSample:(DTXSample*)sample
{
	NSInteger idx = [_managedOutlineView rowForItem:sample];
	
	if(sample.hidden || idx == -1)
	{
		//Sample not found directly. Look for it recursively in sample groups and expand the outline until the item is visible and then select it.
		NSMutableArray* chain = [NSMutableArray new];
		BOOL found = [self _findSample:sample inContainerProxy:self.rootGroupProxy traversalChain:chain];
		
		if(found)
		{
			for (id sampleOrProxy in chain)
			{
				[_managedOutlineView expandItem:sampleOrProxy];
			}
			
			idx = [_managedOutlineView rowForItem:sample];
		}
		else
		{
			[_managedOutlineView selectRowIndexes:NSIndexSet.indexSet byExtendingSelection:NO];
			return;
		}
	}
	
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
		//TODO: Handle ranges again, sorry!
		[_plotController highlightSample:item];
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
		[self setupContainerProxiesReloadOutline:YES];
		[_managedOutlineView scrollRowToVisible:0];
		if([_plotController respondsToSelector:@selector(setFilteredDataProvider:)])
		{
			[_plotController setFilteredDataProvider:nil];
		}
		return;
	}
	
	_rootGroupProxy = nil;
	
	if(_filteredDataProvider == nil)
	{
		_filteredDataProvider = [[DTXFilteredDataProvider alloc] initWithDocument:self.document managedOutlineView:_managedOutlineView sampleClass:self.sampleClass filteredAttributes:self.filteredAttributes];
		_managedOutlineView.dataSource = _filteredDataProvider;
		[_plotController setFilteredDataProvider:_filteredDataProvider];
	}
	
	[_filteredDataProvider filterSamplesWithPredicate:[self predicateForFilter:filter]];
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
	
	[_managedOutlineView scrollRowToVisible:0];
}

- (DTXFilteredDataProvider *)filteredDataProvider
{
	return _filteredDataProvider;
}

- (void)continueFilteringWithFilteredDataProvider:(DTXFilteredDataProvider*)filteredDataProvider;
{
	_filteredDataProvider = filteredDataProvider;
	if([_plotController respondsToSelector:@selector(setFilteredDataProvider:)])
	{
		[_plotController setFilteredDataProvider:_filteredDataProvider];
	}
	
	if(filteredDataProvider == nil)
	{
		return;
	}
	
	_managedOutlineView.dataSource = _filteredDataProvider;
	
	[_managedOutlineView reloadData];
	[_managedOutlineView scrollRowToVisible:0];
}

- (BOOL)supportsSorting
{
	return YES;
}

@end
