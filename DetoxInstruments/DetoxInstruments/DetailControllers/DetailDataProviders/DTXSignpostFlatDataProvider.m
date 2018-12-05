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
	
	DTXColumnInformation* type = [DTXColumnInformation new];
	type.title = NSLocalizedString(@"Type", @"");
	type.minWidth = durationMinWidth;
	
	DTXColumnInformation* category = [DTXColumnInformation new];
	category.title = NSLocalizedString(@"Category", @"");
	category.minWidth = 200;
	
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Name", @"");
	name.minWidth = 300;
	
	DTXColumnInformation* status = [DTXColumnInformation new];
	status.title = NSLocalizedString(@"Status", @"");
	status.minWidth = 100;
	
	return @[duration, type, category, name, status];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeSignpost)];
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
			return signpostSample.category;
		case 3:
			return signpostSample.name;
		case 4:
		{
			return signpostSample.eventStatusString;
		}
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
