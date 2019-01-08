//
//  DTXSignpostNestedDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/6/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSignpostNestedDataProvider.h"
#import "DTXSignpostSummaryRootProxy.h"
#import "DTXSignpostProtocol.h"
#import "DTXDetailOutlineView.h"
#import "DTXEventInspectorDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"
#import "DTXSignpostDataExporter.h"
#import "DTXSignpostNestedRootProxy.h"

@implementation DTXSignpostNestedDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXEventInspectorDataProvider class];
}

- (Class)dataExporterClass
{
	return DTXSignpostDataExporter.class;
}

- (NSString *)identifier
{
	return @"Nested";
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Nested", @"");;
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"samples_nested"];
	image.size = NSMakeSize(16, 16);
	
	return image;
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
		[(DTXDetailOutlineView*)outlineView setRespectsOutlineCellFraming:YES];
	}
}

- (NSArray<DTXColumnInformation *> *)columns
{
	const CGFloat durationMinWidth = 90;
	
	DTXColumnInformation* start = [DTXColumnInformation new];
	start.title = NSLocalizedString(@"Start", @"");
	start.minWidth = 200;
	start.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
	
	DTXColumnInformation* duration = [DTXColumnInformation new];
	duration.title = NSLocalizedString(@"Duration", @"");
	duration.minWidth = durationMinWidth;
	duration.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:YES];
	
	DTXColumnInformation* category = [DTXColumnInformation new];
	category.title = NSLocalizedString(@"Category", @"");
	category.minWidth = 130;
	category.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES];
	
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Name", @"");
	name.minWidth = 165;
	name.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	
	DTXColumnInformation* moreInfo1 = [DTXColumnInformation new];
	moreInfo1.title = NSLocalizedString(@"Additional Info (Start)", @"");
	moreInfo1.minWidth = 155;
	moreInfo1.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"additionalInfoStart" ascending:YES];
	
	DTXColumnInformation* moreInfo2 = [DTXColumnInformation new];
	moreInfo2.title = NSLocalizedString(@"Additional Info (End)", @"");
	moreInfo2.minWidth = 155;
	moreInfo2.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"additionalInfoEnd" ascending:YES];
	
	return @[start, duration, category, name, moreInfo1, moreInfo2];
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
		{
			NSTimeInterval ti = signpostSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
			return [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		}
		case 1:
			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
			{
				return @"—";
			}
			return [[NSFormatter dtx_durationFormatter] stringFromTimeInterval:signpostSample.duration];
		case 2:
			return signpostSample.category;
		case 3:
			return signpostSample.name;
		case 4:
			return signpostSample.additionalInfoStart;
		case 5:
			return signpostSample.additionalInfoEnd;
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
	
	if(sample.isExpandable == NO && sample.endTimestamp == nil)
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
	
	if(sample.isExpandable == NO && sample.endTimestamp == nil)
	{
		return NSLocalizedString(@"Incomplete event", @"");
	}
	
	return nil;
}

- (BOOL)supportsDataFiltering
{
	return NO;
}

- (BOOL)supportsSorting
{
	return NO;
}

- (BOOL)showsTimestampColumn
{
	return NO;
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[@"category", @"name", @"additionalInfoStart", @"additionalInfoEnd"];
}

- (DTXSampleContainerProxy *)rootSampleContainerProxy
{
	return [[DTXSignpostNestedRootProxy alloc] initWithOutlineView:self.managedOutlineView managedObjectContext:self.document.firstRecording.managedObjectContext sampleClass:DTXSignpostSample.class];
}

@end
