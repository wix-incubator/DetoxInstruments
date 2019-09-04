//
//  DTXInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInspectorDataProvider.h"
#import "DTXSignpostProtocol.h"
#import "NSFormatter+PlotFormatters.h"

@interface DTXInspectorDataProvider ()

+ (BOOL)_allowsNilSample;

@end

@implementation DTXInspectorDataProvider

+ (BOOL)_allowsNilSample
{
	return NO;
}

- (instancetype)initWithSample:(__kindof DTXSample *)sample document:(DTXRecordingDocument *)document
{
	self = [super init];
	
	if(self.class._allowsNilSample == NO)
	{
		NSParameterAssert(sample != nil);
	}
	NSParameterAssert(document != nil);
	
	if(self)
	{
		_sample = sample;
		_document = document;
	}
	
	return self;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	return nil;
}

- (BOOL)canCopyInView:(__kindof NSView *)view
{
	return NO;
}

- (BOOL)canSaveAs
{
	return NO;
}

- (IBAction)copyInView:(__kindof NSView *)view sender:(id)sender
{
	//NOOP
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	//NOOP
}

@end

@implementation DTXTagInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXTag* tag = (id)self.sample;
	
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Tag", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Name", @"") description:tag.name]];
	
	NSTimeInterval ti = [tag.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end

@implementation DTXGroupInspectorDataProvider

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	id<DTXSignpost> proxy = (id)self.sample;
	
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Group", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Name", @"") description:proxy.name]];
	
	NSTimeInterval ti = [proxy.timestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	ti = [proxy.endTimestamp ?: self.document.lastRecording.endTimestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end

@implementation DTXRangeInspectorDataProvider
{
	NSDate* _startTimestamp;
	NSDate* _endTimestamp;
	NSUInteger _totalCount;
}

@dynamic sample;

+ (BOOL)_allowsNilSample
{
	return YES;
}

- (instancetype)initWithSamples:(NSArray<__kindof DTXSample*>*)samples sortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors document:(DTXRecordingDocument*)document
{
	self = [super initWithSample:nil document:document];
	
	if(self)
	{
		if([sortDescriptors.firstObject.key isEqualToString:@"timestamp"])
		{
			__kindof DTXSample* first = samples.firstObject;
			__kindof DTXSample* last = samples.lastObject;
			
			if(sortDescriptors.firstObject.ascending == NO)
			{
				swap(first, last);
			}
			
			_startTimestamp = first.timestamp;
			_endTimestamp = [last respondsToSelector:@selector(endTimestamp)] ? [last endTimestamp] : last.timestamp;
		}
		else
		{
			//Slow path
			_startTimestamp = [samples valueForKeyPath:@"@min.timestamp"];
			if([samples.firstObject respondsToSelector:@selector(endTimestamp)])
			{
				_endTimestamp = [samples valueForKeyPath:@"@max.endTimestamp"];
			}
			else
			{
				_endTimestamp = [samples valueForKeyPath:@"@max.timestamp"];
			}
		}
		
		_totalCount = samples.count;
	}
	
	return self;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Multiple Samples", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Selection Count", @"") description:[NSFormatter.dtx_readibleCountFormatter stringFromNumber:@(_totalCount)]]];
	
	NSTimeInterval ti = [_startTimestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	ti = [_endTimestamp timeIntervalSinceReferenceDate] - [self.document.firstRecording.startTimestamp timeIntervalSinceReferenceDate];
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"End", @"") description:[[NSFormatter dtx_secondsFormatter] stringForObjectValue:@(ti)]]];
	
	request.content = content;
	
	rv.contentArray = @[request];
	
	return rv;
}

@end
