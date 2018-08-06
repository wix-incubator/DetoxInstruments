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
#import "DTXEventInspectorDataProvider.h"
#import "DTXSignpostSample+UIExtensions.h"

@implementation DTXSignpostDataProvider

+ (Class)inspectorDataProviderClass
{
	return [DTXEventInspectorDataProvider class];
}

- (void)setManagedOutlineView:(NSOutlineView *)managedOutlineView
{
	[super setManagedOutlineView:managedOutlineView];
	
	[self _enableOutlineRespectIfNeeded];
}

- (void)_enableOutlineRespectIfNeeded
{
	if([self.managedOutlineView respondsToSelector:@selector(setRespectsOutlineCellFraming:)])
	{
		[(DTXDetailOutlineView*)self.managedOutlineView setRespectsOutlineCellFraming:self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished];
	}
}

- (NSArray<DTXColumnInformation*>*)_columnsAtRest
{
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Category / Name", @"");
	name.minWidth = 320;
	
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
	
	DTXColumnInformation* status = [DTXColumnInformation new];
	status.title = NSLocalizedString(@"Status", @"");
	status.minWidth = 150;
	
	return @[name, count, timestamp, duration, minDuration, avgDuration, maxDuration, status];
}

- (NSArray<DTXColumnInformation*>*)_columnsLiveRecording
{
	const CGFloat durationMinWidth = 75;
	
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
	status.minWidth = 150;
	
	return @[duration, type, category, name, status];
}

- (NSArray<DTXColumnInformation *> *)columns
{
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		return self._columnsAtRest;
	}
	
	return self._columnsLiveRecording;
}

- (NSArray<NSNumber *> *)sampleTypes
{
	return @[@(DTXSampleTypeSignpost)];
}

- (NSString*)_formattedStringValueAtRestForItem:(id)item column:(NSUInteger)column
{
	id<DTXSignpost> signpostSample = item;
	DTXSignpostSample* realSignpostSample = (id)signpostSample;
	
	if(signpostSample.isGroup == NO && column != 0 && column != 2 && column != 3 && column != 7)
	{
		return @"—";
	}
	
	if(signpostSample.isGroup == YES && column == 7)
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
			if(signpostSample.isGroup == NO && (realSignpostSample.isEvent || realSignpostSample.endTimestamp == nil))
			{
				return @"—";
			}
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.duration];
		case 4:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.minDuration];
		case 5:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.avgDuration];
		case 6:
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.maxDuration];
		case 7:
			return realSignpostSample.eventStatusString;
		default:
			return nil;
	}
}

- (NSString*)_formattedStringValueLiveRecordForItem:(id)item column:(NSUInteger)column
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
			return signpostSample.isEvent ? NSLocalizedString(@"Event", @"") : NSLocalizedString(@"Interval", @"");
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

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column
{
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		return [self _formattedStringValueAtRestForItem:item column:column];
	}
	
	return [self _formattedStringValueLiveRecordForItem:item column:column];
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
	if(self.document.documentState >= DTXRecordingDocumentStateLiveRecordingFinished)
	{
		return [[DTXSignpostRootProxy alloc] initWithRecording:self.document.recording outlineView:self.managedOutlineView];
	}
	
	return [super rootSampleContainerProxy];
}

- (BOOL)showsTimestampColumn
{
	return NO;
}

@end
