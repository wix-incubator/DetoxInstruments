//
//  DTXDetailController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXDetailController.h"
#import "DTXDataExporter.h"

@implementation DTXDetailController

- (instancetype)initWithDetailDataProvider:(DTXDetailDataProvider*)detailDataProvider
{
	self = [super init];
	
	if(self)
	{
		_detailDataProvider = detailDataProvider;
	}
	
	return self;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(copy:))
	{
		return self.detailDataProvider.canCopy;
	}
	
	return [super validateMenuItem:menuItem];
}

- (BOOL)supportsDataFiltering
{
	return _detailDataProvider.supportsDataFiltering;
}

- (void)updateViewWithInsets:(NSEdgeInsets)insets
{
	
}

- (void)filterSamples:(NSString*)filter
{
	[self.detailDataProvider filterSamplesWithFilter:filter];
}

- (DTXFilteredDataProvider *)filteredDataProvider
{
	if([self.detailDataProvider respondsToSelector:@selector(filteredDataProvider)])
	{
		return self.detailDataProvider.filteredDataProvider;
	}
	
	return nil;
}

- (void)continueFilteringWithFilteredDataProvider:(DTXFilteredDataProvider*)filteredDataProvider
{
	if([self.detailDataProvider respondsToSelector:@selector(continueFilteringWithFilteredDataProvider:)])
	{
		[self.detailDataProvider continueFilteringWithFilteredDataProvider:filteredDataProvider];
	}
}

- (void)loadProviderWithDocument:(DTXRecordingDocument*)document detailDataProviderClass:(Class)detailDataProviderClass
{
	
}

- (void)setDetailDataProvider:(DTXDetailDataProvider *)detailDataProvider
{
	_detailDataProvider = detailDataProvider;
	_detailDataProvider.delegate = self;
}

- (void)selectSample:(DTXSample *)sample
{
	[_detailDataProvider selectSample:sample];
}

- (DTXDataExporter*)dataExporter
{
	return [[_detailDataProvider.dataExporterClass alloc] initWithDocument:_detailDataProvider.document];
}

+ (NSString *)defaultDetailControllerIdentifier
{
	return DTXDetailDataProvider.defaultDetailDataProviderIdentifier;
}

- (NSString *)identifier
{
	return self.detailDataProvider.identifier;
}

- (NSString *)displayName
{
	return self.detailDataProvider.displayName;
}

- (NSImage *)smallDisplayIcon
{
	return self.detailDataProvider.displayIcon;
}

#pragma mark DTXDetailDataProviderDelegate

- (void)dataProvider:(id<DTXDetailDataProvider>)provider didSelectInspectorItem:(DTXInspectorDataProvider*)item;
{
	[self.delegate detailController:self didSelectInspectorItem:item];
}

#pragma mark DTXWindowWideCopyHanler

- (void)copy:(id)sender
{
	[self.detailDataProvider copy:sender];
}

@end
