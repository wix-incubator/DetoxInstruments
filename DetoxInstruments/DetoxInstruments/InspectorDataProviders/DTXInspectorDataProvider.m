//
//  DTXInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXInspectorDataProvider.h"
#import "DTXSignpostProtocol.h"

@implementation DTXInspectorDataProvider

- (instancetype)initWithSample:(__kindof DTXSample *)sample document:(DTXRecordingDocument *)document
{
	self = [super init];
	
	NSParameterAssert(sample != nil);
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

- (BOOL)canCopy
{
	return NO;
}

- (BOOL)canSaveAs
{
	return NO;
}

- (IBAction)copy:(id)sender targetView:(__kindof NSView *)targetView
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
