//
//  DTXActivitySummaryDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 6/24/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXActivitySummaryDataProvider.h"
#import "DTXActivitySummaryRootProxy.h"
#import "DTXSignpostProtocol.h"
#import "DTXDetailOutlineView.h"
#import "DTXEventInspectorDataProvider.h"
#import "DTXActivitySample+UIExtensions.h"
#import "DTXSignpostDataExporter.h"
#import "DTXSignpostAdditionalInfoEndProxy.h"

@implementation DTXActivitySummaryDataProvider

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
	return NSLocalizedString(@"Summary", @"");;
}

- (NSImage *)displayIcon
{
	NSImage* image = [NSImage imageNamed:@"samples_nonflat"];
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
	DTXColumnInformation* name = [DTXColumnInformation new];
	name.title = NSLocalizedString(@"Activity / Object", @"");
	name.minWidth = 320;
	
	const CGFloat durationMinWidth = 90;
	
	DTXColumnInformation* count = [DTXColumnInformation new];
	count.title = NSLocalizedString(@"Count", @"");
	count.minWidth = 40;
	
	DTXColumnInformation* timestamp = [DTXColumnInformation new];
	timestamp.title = NSLocalizedString(@"Start", @"");
	timestamp.minWidth = 80;
	
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
}

- (Class)sampleClass
{
	return DTXActivitySample.class;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if([item isKindOfClass:DTXSignpostSample.class])
	{
		DTXSignpostSample* realSignpostSample = item;
			
		return realSignpostSample.additionalInfoEnd.length > 0;
	}
	
	return [super outlineView:outlineView isItemExpandable:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	if([item isKindOfClass:DTXSignpostSample.class])
	{
		return [[DTXSignpostAdditionalInfoEndProxy alloc] initWithSignpostSample:item];
	}
	
	return [super outlineView:outlineView child:index ofItem:item];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if([item isKindOfClass:DTXSignpostSample.class])
	{
		return 1;
	}
	
	return [super outlineView:outlineView numberOfChildrenOfItem:item];
}

- (NSString*)formattedStringValueForItem:(id)item column:(NSUInteger)column
{
	id<DTXSignpost> signpostSample = item;
	DTXActivitySample* realSignpostSample = (id)signpostSample;
	
//	if(signpostSample.isExpandable == NO && column != 0 && column != 2 && column != 3 && column != 7)
//	{
//		return @"—";
//	}
	
//	if(signpostSample.isExpandable == YES && column == 7)
//	{
//		return @"—";
//	}
	
	BOOL isLeaf = [signpostSample isKindOfClass:DTXActivitySample.class] || [signpostSample isKindOfClass:DTXSignpostAdditionalInfoEndProxy.class];
	
	switch (column)
	{
		case 0:
			if(realSignpostSample.isExpandable)
			{
				return signpostSample.name;
			}
			
			if([signpostSample isKindOfClass:DTXSignpostAdditionalInfoEndProxy.class])
			{
				return realSignpostSample.additionalInfoEnd;
			}
			
			return realSignpostSample.additionalInfoStart.length > 0 ? realSignpostSample.additionalInfoStart : realSignpostSample.name;
		case 1:
			if(isLeaf)
			{
				return @" ";
			}
			
			return [NSFormatter.dtx_stringFormatter stringForObjectValue:@(signpostSample.count)];
		case 2:
		{
			NSTimeInterval ti = signpostSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
			return [[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)];
		}
		case 3:
			if(realSignpostSample.isEvent || realSignpostSample.endTimestamp == nil)
			{
				return @"—";
			}
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.duration];
		case 4:
			if(isLeaf == YES || realSignpostSample.isEvent || realSignpostSample.endTimestamp == nil)
			{
				return @" ";
			}
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.minDuration];
		case 5:
			if(isLeaf == YES || realSignpostSample.isEvent || realSignpostSample.endTimestamp == nil)
			{
				return @" ";
			}
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.avgDuration];
		case 6:
			if(isLeaf == YES || realSignpostSample.isEvent || realSignpostSample.endTimestamp == nil)
			{
				return @" ";
			}
			return [NSFormatter.dtx_durationFormatter stringFromTimeInterval:signpostSample.maxDuration];
		default:
			return nil;
	}
}

- (NSColor *)backgroundRowColorForItem:(id)item
{
	DTXActivitySample* sample = item;
	return sample.plotControllerColor;
}

- (BOOL)supportsDataFiltering
{
	return YES;
}

- (BOOL)supportsSorting
{
	return NO;
}

- (NSArray<NSString *> *)filteredAttributes
{
	return @[@"category", @"name", @"additionalInfoStart", @"additionalInfoEnd"];
}

- (DTXSampleContainerProxy *)rootSampleContainerProxy
{
	return [[DTXActivitySummaryRootProxy alloc] initWithManagedObjectContext:self.document.viewContext outlineView:self.managedOutlineView];
}

- (BOOL)showsTimestampColumn
{
	return NO;
}

@end
