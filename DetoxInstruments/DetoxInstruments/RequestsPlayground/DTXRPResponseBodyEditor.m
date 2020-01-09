//
//  DTXRPResponseBodyEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRPResponseBodyEditor.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSColor+UIAdditions.h"
#import "NSURL+UIAdditions.h"
#import "NSString+FileNames.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXNetworkInspectorDataProvider.h"

@interface DTXRPResponseBodyEditor ()
{
	IBOutlet NSTableView* _tableView;
	DTXInspectorContentTableDataSource* _tableDataSource;
	
	NSHTTPURLResponse* _response;
	NSData* _body;
	NSError* _error;
	NSURLSessionTaskMetrics* _metrics;
}

@end

@implementation DTXRPResponseBodyEditor

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_tableDataSource = [DTXInspectorContentTableDataSource new];
	_tableDataSource.managedTableView = _tableView;
}

- (BOOL)_hasImage
{
	if(_response == nil || _body == nil)
	{
		return NO;
	}
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(_response.MIMEType), NULL);
	
	BOOL rv = UTI != NULL ? UTTypeConformsTo(UTI, kUTTypeScalableVectorGraphics) == NO && UTTypeConformsTo(UTI, kUTTypeImage) : NO;
	
	if(UTI != NULL)
	{
		CFRelease(UTI);
	}
	
	return rv;
}

- (void)_reloadTable
{
	NSMutableArray* contentArray = [NSMutableArray new];
	
	NSUInteger statusCode = 0;
	NSString* statusLocalized = nil;
	if([_response isKindOfClass:NSHTTPURLResponse.class])
	{
		statusCode = [(NSHTTPURLResponse*)_response statusCode];
		statusLocalized = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
	}

	if(_error != nil || statusCode >= 400)
	{
		DTXInspectorContent* responsePreview = [DTXInspectorContent new];
		responsePreview.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Error", @"") attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName: [NSColor warning3Color]}];
		if(_error != nil)
		{
			responsePreview.content = @[[DTXInspectorContentRow contentRowWithTitle:nil description:_error.localizedFailureReason ?: _error.localizedDescription]];
		}
		else
		{
			responsePreview.content = @[[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Response Code", @"") description:[NSString stringWithFormat:@"%@ (%@)", @(statusCode), statusLocalized]]];
		}
		[contentArray addObject:responsePreview];
	}
	
	if(_metrics != nil)
	{
		DTXInspectorContent* metrics = [DTXInspectorContent new];
		metrics.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Metrics", @"") attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
		
		NSMutableArray* content = [NSMutableArray new];

		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSDateFormatter localizedStringFromDate:_metrics.taskInterval.startDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Duration", @"") description:[[NSFormatter dtx_durationFormatter] stringFromTimeInterval:_metrics.taskInterval.duration]]];
		
//		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Start Date", @"") description:@""]];
		
//		[[_response.allHeaderFields.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
//			[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:_response.allHeaderFields[key]]];
//		}];
		
		metrics.content = content;
		
		[contentArray addObject:metrics];
	}
	
	if(_response != nil && [_response respondsToSelector:@selector(allHeaderFields)])
	{
		DTXInspectorContent* responseHeaders = [DTXInspectorContent new];
		responseHeaders.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Response Headers", @"") attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
		
		NSMutableArray* content = [NSMutableArray new];
		
		[[_response.allHeaderFields.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:_response.allHeaderFields[key]]];
		}];
		
		responseHeaders.content = content;
		
		[contentArray addObject:responseHeaders];
	}
	
	DTXInspectorContent* responsePreview = [DTXNetworkInspectorDataProvider inspctorContentForData:_body response:_response];
	if(responsePreview != nil)
	{
		responsePreview.attributedTitle = [[NSAttributedString alloc] initWithString:responsePreview.title attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
		[contentArray addObject:responsePreview];
	}
	
	_tableDataSource.contentArray = contentArray;
}

- (void)setBody:(NSData *)body response:(NSURLResponse*)response error:(NSError*)error metrics:(NSURLSessionTaskMetrics*)metrics
{
	_body = body;
	_response = (id)response;
	_error = error;
	_metrics = metrics;
	[self _reloadTable];
}

@end
