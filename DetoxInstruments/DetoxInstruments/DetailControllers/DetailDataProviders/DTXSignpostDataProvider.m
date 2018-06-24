//
//  DTXSignpostDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXSignpostDataProvider.h"

@implementation DTXSignpostDataProvider

+ (Class)inspectorDataProviderClass
{
	return nil;//[DTXNetworkInspectorDataProvider class];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	DTXColumnInformation* endTime = [DTXColumnInformation new];
	endTime.title = NSLocalizedString(@"End Time", @"");
	endTime.minWidth = 72;
	
	DTXColumnInformation* duration = [DTXColumnInformation new];
	duration.title = NSLocalizedString(@"Duration", @"");
	duration.minWidth = 42;
	
	DTXColumnInformation* type = [DTXColumnInformation new];
	type.title = NSLocalizedString(@"Type", @"");
	type.minWidth = 60;
	
	DTXColumnInformation* status = [DTXColumnInformation new];
	status.title = NSLocalizedString(@"Status", @"");
	status.minWidth = 150;

	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Name", @"");
	name.automaticallyGrowsWithTable = YES;
	
	return @[endTime, duration, type, status, name];
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeSignpost)];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column;
{
	DTXSignpostSample* signpostSample = item;
	
	switch(column)
	{
		case 0:
			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
			{
				return @"--";
			}
			
			return [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(signpostSample.endTimestamp.timeIntervalSinceReferenceDate - self.document.recording.startTimestamp.timeIntervalSinceReferenceDate)];
		case 1:
			if(signpostSample.isEvent || signpostSample.endTimestamp == nil)
			{
				return @"--";
			}
			return [[NSFormatter dtx_durationFormatter] stringFromDate:signpostSample.timestamp toDate:signpostSample.endTimestamp];
		case 2:
			return signpostSample.isEvent ? NSLocalizedString(@"Event", @"") : NSLocalizedString(@"Interval", @"");
		case 3:
		{
			if(signpostSample.eventStatus == DTXEventStatusError)
			{
				return NSLocalizedString(@"Error", @"");
			}
			
			NSMutableString* completed = [NSLocalizedString(@"Completed", @"") mutableCopy];
			if(signpostSample.eventStatus > DTXEventStatusError)
			{
				[completed appendString:[NSString stringWithFormat:@" (Category %@)", @(signpostSample.eventStatus - DTXEventStatusError)]];
			}
			
			return completed;
		}
		case 4:
			return signpostSample.name;
		default:
			return @"";
	}
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
	return @[@"name", @"additionalInfoStart", @"additionalInfoEnd"];
}

@end
