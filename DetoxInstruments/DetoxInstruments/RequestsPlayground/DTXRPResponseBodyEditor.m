//
//  DTXRPResponseBodyEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRPResponseBodyEditor.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSColor+UIAdditions.h"
#import "NSURL+UIAdditions.h"
#import "NSString+FileNames.h"
#import "NSColor+UIAdditions.h"
#import "NSFormatter+PlotFormatters.h"

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
	
	NSImage* image;
	if(self._hasImage && _body != nil)
	{
		image = [[NSImage alloc] initWithData:_body];
	}
	else
	{
		if(_response != nil && _response.MIMEType != nil && _body != nil)
		{
			NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(_response.MIMEType), NULL));
			image = [[NSWorkspace sharedWorkspace] iconForFileType:UTI];
			image.size = NSMakeSize(128, 128);
		}
	}
	
	if(image)
	{
		DTXInspectorContent* responsePreview = [DTXInspectorContent new];
		responsePreview.attributedTitle = [[NSAttributedString alloc] initWithString:self._bestGuessFileName attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
		responsePreview.image = image;
		
		NSButton* previewButton = [NSButton new];
		previewButton.bezelStyle = NSBezelStyleRounded;
		previewButton.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
		previewButton.title = NSLocalizedString(@"Open", @"");
		previewButton.target = self;
		previewButton.action = @selector(open:);
		previewButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSButton* saveButton = [NSButton new];
		saveButton.bezelStyle = NSBezelStyleRounded;
		saveButton.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
		saveButton.title = NSLocalizedString(@"Save As…", @"");
		saveButton.target = self;
		saveButton.action = @selector(saveAs:);
		saveButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSButton* shareButton = [NSButton new];
		[shareButton sendActionOn:NSEventMaskLeftMouseDown];
		shareButton.bezelStyle = NSBezelStyleRounded;
		shareButton.image = [NSImage imageNamed:NSImageNameShareTemplate];
		shareButton.target = self;
		shareButton.action = @selector(share:);
		shareButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		responsePreview.buttons = @[previewButton, saveButton, shareButton];
		
		[contentArray addObject:responsePreview];
	}
	
	_tableDataSource.contentArray = contentArray;
}

- (NSString*)_bestGuessFileName
{
	NSString* fileName = _response.suggestedFilename;
	
	if(fileName.length == 0)
	{
		fileName = _response.URL.lastPathComponent;
		
		if(fileName.length == 0)
		{
			fileName = @"file";
		}
		
		NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(_response.MIMEType), NULL));
		NSString* extension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(CF(UTI), kUTTagClassFilenameExtension));
		
		if(extension && [fileName.pathExtension isEqualToString:extension] == NO)
		{
			fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
		}
		
		fileName = fileName.stringBySanitizingForFileName;
	}
	
	return fileName;
}

- (NSURL*)_prepareTempFile
{
	NSString* fileName = self._bestGuessFileName;
	NSURL* target = [NSURL.temporaryDirectoryURL URLByAppendingPathComponent:fileName];
	;
	[_body writeToURL:target atomically:YES];
	
	return target;
}

- (IBAction)saveAs:(id)sender
{
	[self saveAs:sender inWindow:[sender window]];
}

- (IBAction)share:(id)sender
{
	NSSharingServicePicker* picker = [[NSSharingServicePicker alloc] initWithItems:@[self._prepareTempFile]];
	[picker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMaxY];
}

- (IBAction)open:(id)sender
{
	NSURL* target = self._prepareTempFile;
	
	[NSWorkspace.sharedWorkspace openURL:target];
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	NSString* fileName = self._bestGuessFileName;
	
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setNameFieldStringValue:fileName];
	panel.contentView.wantsLayer = YES;
	panel.contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	[panel beginSheetModalForWindow:window completionHandler:^ (NSInteger result) {
		if (result == NSModalResponseOK)
		{
			NSURL* theFile = [panel URL];
			
			[_body writeToURL:theFile atomically:YES];
		}
	}];
	
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
