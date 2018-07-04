//
//  DTXSignpostDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostDataProvider.h"
#import "DTXSignpostRootProxy.h"
#import "DTXSignpostProtocol.h"
#import "DTXDetailOutlineView.h"

@implementation DTXSignpostDataProvider

+ (Class)inspectorDataProviderClass
{
	return nil;//[DTXNetworkInspectorDataProvider class];
}

- (void)setManagedOutlineView:(NSOutlineView *)managedOutlineView
{
	[super setManagedOutlineView:managedOutlineView];
	
	if([managedOutlineView respondsToSelector:@selector(setRespectsOutlineCellFraming:)])
	{
		[(DTXDetailOutlineView*)managedOutlineView setRespectsOutlineCellFraming:YES];
	}
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Category / Name", @"");
	name.minWidth = 450;
	
	const CGFloat durationMinWidth = 75;
	
	DTXColumnInformation* count = [DTXColumnInformation new];
	count.title = NSLocalizedString(@"Count", @"");
	count.minWidth = durationMinWidth;
	
	DTXColumnInformation* timestamp = [DTXColumnInformation new];
	timestamp.title = NSLocalizedString(@"Start", @"");
	timestamp.minWidth = durationMinWidth;
	
	DTXColumnInformation* duration = [DTXColumnInformation new];
	duration.title = NSLocalizedString(@"Duration", @"");
	duration.minWidth = durationMinWidth;
	
	DTXColumnInformation* minDuration = [DTXColumnInformation new];
	minDuration.title = NSLocalizedString(@"Min Duration", @"");
	minDuration.minWidth = durationMinWidth;
	
	DTXColumnInformation* avgDuration = [DTXColumnInformation new];
	avgDuration.title = NSLocalizedString(@"Avg Duration", @"");
	avgDuration.minWidth = durationMinWidth;
	
	DTXColumnInformation* maxDuration = [DTXColumnInformation new];
	maxDuration.title = NSLocalizedString(@"Max Duration", @"");
	maxDuration.minWidth = durationMinWidth;
	
	return @[name, count, timestamp, duration, minDuration, avgDuration, maxDuration];
	
//	DTXColumnInformation* endTime = [DTXColumnInformation new];
//	endTime.title = NSLocalizedString(@"End Time", @"");
//	endTime.minWidth = 72;
//
//	DTXColumnInformation* duration = [DTXColumnInformation new];
//	duration.title = NSLocalizedString(@"Duration", @"");
//	duration.minWidth = 42;
//
//	DTXColumnInformation* category = [DTXColumnInformation new];
//	category.title = NSLocalizedString(@"Category", @"");
//	category.minWidth = 150;
//
//	DTXColumnInformation* type = [DTXColumnInformation new];
//	type.title = NSLocalizedString(@"Type", @"");
//	type.minWidth = 60;
//
//	DTXColumnInformation* status = [DTXColumnInformation new];
//	status.title = NSLocalizedString(@"Status", @"");
//	status.minWidth = 150;
//
//	DTXColumnInformation* name = [DTXColumnInformation new];
//	name.title = NSLocalizedString(@"Name", @"");
//	name.automaticallyGrowsWithTable = YES;
//
//	return @[endTime, duration, category, type, status, name];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeSignpost)];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	id<DTXSignpost> signpostSample = item;

	if([signpostSample isKindOfClass:DTXSampleContainerProxy.class] == NO && column != 0 && column != 2 && column != 3)
	{
		return @"—";
	}
	
	if([signpostSample isKindOfClass:DTXSampleContainerProxy.class] == YES && column == 2)
	{
		return @"—";
	}
	
	switch (column)
	{
		case 0:
			return signpostSample.name;
		case 1:
			return [NSFormatter.dtx_stringFormatter stringForObjectValue:@(signpostSample.count)];
		case 2:
		{
			NSTimeInterval ti = signpostSample.timestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate;
			return [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		}
		case 3:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.duration];
		case 4:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.minDuration];
		case 5:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.avgDuration];
		case 6:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.maxDuration];
		default:
			return 0;
	}
	
//	switch(column)
//	{
//		case 0:
//			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
//			{
//				return @"—";
//			}
//
//			return [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(signpostSample.endTimestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate)];
//		case 1:
//			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
//			{
//				return @"—";
//			}
//			return [[NSFormatter dtx_durationFormatter] stringFromDate:signpostSample.timestamp toDate:signpostSample.endTimestamp];
//		case 2:
//			return signpostSample.category;
//		case 3:
//			return signpostSample.isEvent ? NSLocalizedString(@"Event", @"") : NSLocalizedString(@"Interval", @"");
//		case 4:
//		{
//			if(signpostSample.eventStatus == DTXEventStatusError)
//			{
//				return NSLocalizedString(@"Error", @"");
//			}
//
//			NSMutableString* completed = [NSLocalizedString(@"Completed", @"") mutableCopy];
//			if(signpostSample.eventStatus > DTXEventStatusError)
//			{
//				[completed appendString:[NSString stringWithFormat:@" (Category %@)", @(signpostSample.eventStatus - DTXEventStatusError)]];
//			}
//
//			return completed;
//		}
//		case 5:
//			return signpostSample.name;
//		default:
//			return nil;
//	}
	
	return nil;
}

- (NSColor *)backgroundRowColorForItem:(id)item
{
	DTXSignpostSample* sample = item;
	
	if(sample.eventStatus == DTXEventStatusError)
	{
		return NSColor.warning3Color;
	}
	
	return NSColor.controlBackgroundColor;
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
	return [[DTXSignpostRootProxy alloc] initWithRecording:self.document.recording outlineView:self.managedOutlineView];
}

- (BOOL)showsTimestampColumn
{
	return NO;
}

@end
