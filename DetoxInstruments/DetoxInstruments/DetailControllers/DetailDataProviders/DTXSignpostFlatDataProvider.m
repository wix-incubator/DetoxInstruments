//
//  DTXSignpostFlatDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/5/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostFlatDataProvider.h"
#import "DTXSignpostRootProxy.h"
#import "DTXSignpostProtocol.h"
#import "DTXDetailOutlineView.h"
#import "DTXEventInspectorDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXSignpostDataExporter.h"

@implementation DTXSignpostFlatDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXEventInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXSignpostDataExporter.class;
}

- (NSString *)displayName
{
	return NSLocalizedString(@"List", @"");;
}

- (void)setManagedOutlineView:(NSOutlineView *)managedOutlineView
{
	[self _enableOutlineRespectIfNeededForOutlineView:managedOutlineView];
	
	[super setManagedOutlineView:managedOutlineView];
}

- (void)_enableOutlineRespectIfNeededForOutlineView:(NSOutlineView*)outlineView
{
	if([outlineView respondsToSelector:@selector(setRespectsOutlineCellFraming:)])
	{
		[(DTXDetailOutlineView*)outlineView setRespectsOutlineCellFraming:NO];
	}
}

- (NSArray<DTXColumnInformation *> *)columns
{
	const CGFloat durationMinWidth = 80;
	
	DTXColumnInformation* duration = [DTXColumnInformation new];
	duration.title = NSLocalizedString(@"Duration", @"");
	duration.minWidth = durationMinWidth;
	duration.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:YES];
	
	DTXColumnInformation* type = [DTXColumnInformation new];
	type.title = NSLocalizedString(@"Type", @"");
	type.minWidth = durationMinWidth;
	type.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isEvent" ascending:YES];
	
	DTXColumnInformation* category = [DTXColumnInformation new];
	category.title = NSLocalizedString(@"Category", @"");
	category.minWidth = 155;
	category.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES];
	
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Name", @"");
	name.minWidth = 155;
	name.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	
	DTXColumnInformation* status = [DTXColumnInformation new];
	status.title = NSLocalizedString(@"Status", @"");
	status.minWidth = 100;
	status.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"eventStatus" ascending:YES];
	
	DTXColumnInformation* moreInfo1 = [DTXColumnInformation new];
	moreInfo1.title = NSLocalizedString(@"Additional Info (Start)", @"");
	moreInfo1.minWidth = 155;
	moreInfo1.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"additionalInfoStart" ascending:YES];
	
	DTXColumnInformation* moreInfo2 = [DTXColumnInformation new];
	moreInfo2.title = NSLocalizedString(@"Additional Info (End)", @"");
	moreInfo2.minWidth = 155;
	moreInfo2.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"additionalInfoEnd" ascending:YES];
	
	return @[duration, type, status, category, name, moreInfo1, moreInfo2];
}

- (Class)sampleClass
{
	return DTXSignpostSample.class;
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column
{
	DTXSignpostSample* signpostSample = item;
	
	switch(column)
	{
		case 0:
			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
			{
				return @"—";
			}
			return [[NSFormatter dtx_durationFormatter] stringFromTimeInterval:signpostSample.duration];
		case 1:
			return signpostSample.eventTypeString;
		case 2:
			return signpostSample.eventStatusString;
		case 3:
			return signpostSample.category;
		case 4:
			return signpostSample.name;
		case 5:
			return signpostSample.additionalInfoStart;
		case 6:
			return signpostSample.additionalInfoEnd;
		case 7:
		default:
			return nil;
	}
}

- (NSColor *)backgroundRowColorForItem:(id)item
{
	DTXSignpostSample* sample = item;
	
	if(sample.eventStatus == DTXEventStatusPrivateError)
	{
		return NSColor.warning3Color;
	}
	
	if(sample.isGroup == NO && sample.endTimestamp == nil)
	{
		return NSColor.warningColor;
	}
	
	return sample.plotControllerColor;
}

- (NSString*)statusTooltipforItem:(id)item
{
	DTXSignpostSample* sample = item;
	
	if(sample.eventStatus == DTXEventStatusPrivateError)
	{
		return NSLocalizedString(@"Event error", @"");
	}
	
	if(sample.isGroup == NO && sample.endTimestamp == nil)
	{
		return NSLocalizedString(@"Incomplete event", @"");
	}
	
	return nil;
}

- (BOOL)supportsDataFiltering
{
	return YES;
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[@"category", @"name", @"additionalInfoStart", @"additionalInfoEnd"];
}

- (DTXSampleContainerProxy *)rootSampleContainerProxy
{
	return [super rootSampleContainerProxy];
}

@end
