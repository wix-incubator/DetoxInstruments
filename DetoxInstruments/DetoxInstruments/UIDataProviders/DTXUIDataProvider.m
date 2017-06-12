//
//  DTXUIDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 08/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXUIDataProvider.h"
#import "DTXInstrumentsModel.h"
#import "DTXInstrumentsModelUIExtensions.h"
#import "DTXSampleGroup+UIExtensions.h"
#import "DTXSampleGroupProxy.h"
#import "NSFormatter+PlotFormatters.h"

@interface DTXUIDataProvider () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end

@implementation DTXUIDataProvider
{
	DTXDocument* _document;
	DTXSampleGroupProxy* _rootGroupProxy;
}

- (instancetype)initWithDocument:(DTXDocument*)document
{
	self = [super init];
	
	if(self)
	{
		_document = document;
//		_currentlyDisplayedSamples = [_currentDocument.recording.rootSampleGroup samplesWithTypes:@[@(DTXSampleTypePerformance), @(DTXSampleTypeAdvancedPerformance)] includingGroups:YES];
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
	
	NSLog(@"rv=%@", @(rv.count));
	return rv;
}

- (void)setManagedOutlineView:(NSOutlineView *)outlineView
{
	_managedOutlineView.delegate = nil;
	_managedOutlineView.dataSource = nil;
	
	[_managedOutlineView setOutlineTableColumn:[_managedOutlineView tableColumnWithIdentifier:@"DTXTimestampColumn"]];
	
	[_managedOutlineView.tableColumns.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(idx == 0)
		{
			return;
		}
		
		[_managedOutlineView removeTableColumn:obj];
	}];
	
	[_managedOutlineView reloadData];
	
	_managedOutlineView = outlineView;
	
	_managedOutlineView.delegate = self;
	_managedOutlineView.dataSource = self;
	
	[self.columnTitles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];
		column.title = obj;
		column.resizingMask = NSTableColumnAutoresizingMask;
		column.minWidth = 500;
		[_managedOutlineView addTableColumn:column];
		
		if(idx == 0)
		{
			[_managedOutlineView setOutlineTableColumn:column];
		}
	}];
	
	_rootGroupProxy = [DTXSampleGroupProxy new];
	_rootGroupProxy.samples = [self _prepareSamplesForGroup:_document.recording.rootSampleGroup];
	
	[_managedOutlineView reloadData];
	[_managedOutlineView expandItem:nil expandChildren:YES];
}

- (DTXSampleType)sampleType
{
	return DTXSampleTypeUnknown;
}

- (NSUInteger)outlineColumnIndex;
{
	return 0;
}

- (NSArray<NSString*>*)columnTitles
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
	
	NSLog(@"%@", @(currentGroup.samples.count));
	
	return currentGroup.samples.count;
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

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	return @"";
}

- (NSFont*)_monospacedNumbersFontForFont:(NSFont*)font bold:(BOOL)bold
{
	NSFontDescriptor* fontDescriptor = [font.fontDescriptor fontDescriptorByAddingAttributes:@{NSFontTraitsAttribute: @{NSFontWeightTrait: @(bold ? NSFontWeightBold : NSFontWeightRegular)}, NSFontFeatureSettingsAttribute: @[@{NSFontFeatureTypeIdentifierKey: @(kNumberSpacingType), NSFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]}];
	return [NSFont fontWithDescriptor:fontDescriptor size:font.pointSize];
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
		
		return cellView;
	}
	
	NSTableCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXTextCell" owner:nil];
	
	if([item isKindOfClass:[DTXSampleGroupProxy class]])
	{
		cellView.textField.stringValue = ((DTXSampleGroupProxy*)item).name;
	}
	else
	{
		cellView.textField.stringValue = [self formattedStringValueForItem:item column:[tableColumn.identifier integerValue]];
	}
	
	cellView.textField.font = [self _monospacedNumbersFontForFont:cellView.textField.font bold:[item isKindOfClass:[DTXSampleGroupProxy class]]];
	
	return cellView;
}



@end
