//
//  DTXNetworkInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXNetworkInspectorDataProvider.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import <CoreServices/CoreServices.h>
#import "NSString+FileNames.h"
#import "NSURL+UIAdditions.h"
#import "DTXRequestsPlaygroundWindowController.h"

@implementation DTXNetworkInspectorDataProvider

- (BOOL)_hasImage
{
	DTXNetworkSample* networkSample = self.sample;
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(networkSample.responseMIMEType), NULL);
	
	BOOL rv = UTI != NULL ? UTTypeConformsTo(UTI, kUTTypeScalableVectorGraphics) == NO && UTTypeConformsTo(UTI, kUTTypeImage) : NO;
	
	if(UTI != NULL)
	{
		CFRelease(UTI);
	}
	
	return rv;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	NSMutableArray* contentArray = [NSMutableArray new];
	
	DTXNetworkSample* networkSample = self.sample;
	
	DTXInspectorContentTableDataSource* rv = [DTXInspectorContentTableDataSource new];
	
	DTXInspectorContent* request = [DTXInspectorContent new];
	request.title = NSLocalizedString(@"Request", @"");
	
	NSMutableArray<DTXInspectorContentRow*>* content = [NSMutableArray new];
	
	NSTimeInterval ti = networkSample.timestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
	
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"URL", @"") description:networkSample.url]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"HTTP Method", @"") description:networkSample.requestHTTPMethod]];
	[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Size", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(networkSample.requestDataLength)]]];
	
	NSButton* requestEditor = [NSButton new];
	requestEditor.bezelStyle = NSBezelStyleRounded;
	requestEditor.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
	requestEditor.title = NSLocalizedString(@"Open in Requests Playground", @"");
	requestEditor.target = self;
	requestEditor.action = @selector(openInRequestsPlayground:);
	requestEditor.translatesAutoresizingMaskIntoConstraints = NO;
	
	request.buttons = @[requestEditor];
	
	request.content = content;
	
	DTXInspectorContent* requestHeaders;
	if(networkSample.requestHeaders.count > 0)
	{
		requestHeaders = [DTXInspectorContent new];
		requestHeaders.title = NSLocalizedString(@"Request Headers", @"");
		
		content = [NSMutableArray new];
		
		[[networkSample.requestHeaders.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:networkSample.requestHeaders[key]]];
		}];
		
		requestHeaders.content = content;
	}
	
	DTXInspectorContent* response = [DTXInspectorContent new];
	response.title = NSLocalizedString(@"Response", @"");
	
	content = [NSMutableArray new];
	
	BOOL wasError = networkSample.responseError.length > 0;
	
	if(networkSample.responseTimestamp == nil || networkSample.responseStatusCode == 0)
	{
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:@"−"]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Status", @"") description: wasError ? NSLocalizedString(@"Error", @"") : NSLocalizedString(@"Pending", @"") color:NSColor.warning3Color]];
		if(wasError)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Error", @"") description:networkSample.responseError]];
		}
		response.content = content;
		
		[contentArray addObject:response];
	}
	else
	{
		ti = networkSample.responseTimestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate;
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Time", @"") description:[NSFormatter.dtx_secondsFormatter stringForObjectValue:@(ti)]]];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Duration", @"") description:[[NSFormatter dtx_durationFormatter] stringFromDate:networkSample.timestamp toDate:networkSample.responseTimestamp]]];
		
		NSString* status = [NSString stringWithFormat:@"%@%@", @(networkSample.responseStatusCode), networkSample.responseStatusCodeString ? [NSString stringWithFormat:@" (%@)", networkSample.responseStatusCodeString] : @""];
		
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Status", @"") description:status color:networkSample.responseStatusCode < 200 || networkSample.responseStatusCode >= 400 ? NSColor.warning3Color : NSColor.labelColor]];
		if(wasError)
		{
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Error", @"") description:networkSample.responseError]];
		}
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"Data Size", @"") description:[NSFormatter.dtx_memoryFormatter stringForObjectValue:@(networkSample.responseDataLength)]]];
		[content addObject:[DTXInspectorContentRow contentRowWithTitle:NSLocalizedString(@"MIME Type", @"") description:networkSample.responseMIMEType]];
		
		response.content = content;
		
		[contentArray addObject:response];
		
		NSImage* image;
		if(self._hasImage && networkSample.responseData.data)
		{
			image = [[NSImage alloc] initWithData:networkSample.responseData.data];
		}
		else
		{
			if(networkSample.responseMIMEType && networkSample.responseData.data)
			{
				NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(networkSample.responseMIMEType), NULL));
				image = [[NSWorkspace sharedWorkspace] iconForFileType:UTI];
				image.size = NSMakeSize(128, 128);
			}
		}
		
		if(image)
		{
			DTXInspectorContent* responsePreview = [DTXInspectorContent new];
			responsePreview.title = NSLocalizedString(@"Response Preview", @"");
			responsePreview.image = image;
			responsePreview.setupForWindowWideCopy = YES;
			
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
		
		DTXInspectorContent* responseHeaders = [DTXInspectorContent new];
		responseHeaders.title = NSLocalizedString(@"Response Headers", @"");
		
		content = [NSMutableArray new];
		
		[[networkSample.responseHeaders.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
			[content addObject:[DTXInspectorContentRow contentRowWithTitle:key description:networkSample.responseHeaders[key]]];
		}];
		
		responseHeaders.content = content;
		
		[contentArray addObject:responseHeaders];
	}
	
	[contentArray addObject:request];
	if(requestHeaders)
	{
		[contentArray addObject:requestHeaders];
	}
	
	rv.contentArray = contentArray;
	
	return rv;
}

- (BOOL)canCopy
{
	return self._hasImage;
}

- (BOOL)canSaveAs
{
	return YES;
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

- (void)copy:(id)sender targetView:(__kindof NSView *)targetView
{
	DTXNetworkSample* networkSample = self.sample;
	
	if(networkSample.responseDataLength == 0)
	{
		return;
	}
	
	if(self._hasImage)
	{
		NSImage* image = [[NSImage alloc] initWithData:networkSample.responseData.data];
		
		[[NSPasteboard generalPasteboard] clearContents];
		[[NSPasteboard generalPasteboard] writeObjects:@[image]];
	}
}

- (NSString*)_bestGuessFileName
{
	DTXNetworkSample* networkSample = self.sample;
	NSString* fileName = networkSample.responseSuggestedFilename;
	
	if(fileName.length == 0)
	{
		fileName = networkSample.url.lastPathComponent;
		
		if(fileName.length == 0)
		{
			fileName = @"file";
		}
		
		NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(networkSample.responseMIMEType), NULL));
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
	
	DTXNetworkSample* networkSample = self.sample;
	[networkSample.responseData.data writeToURL:target atomically:YES];
	
	return target;
}

- (IBAction)open:(id)sender
{
	NSURL* target = self._prepareTempFile;
	
	[NSWorkspace.sharedWorkspace openURL:target];
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	DTXNetworkSample* networkSample = self.sample;
	
	NSString* fileName = self._bestGuessFileName;
	
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setNameFieldStringValue:fileName];
	panel.contentView.wantsLayer = YES;
	panel.contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	[panel beginSheetModalForWindow:window completionHandler:^ (NSInteger result) {
		if (result == NSModalResponseOK)
		{
			NSURL* theFile = [panel URL];

			[networkSample.responseData.data writeToURL:theFile atomically:YES];
		}
	}];

}

- (IBAction)openInRequestsPlayground:(id)sender
{
	NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"RequestsPlayground" bundle:nil];
	DTXRequestsPlaygroundWindowController* wc = [storyboard instantiateInitialController];
	[wc loadRequestDetailsFromNetworkSample:self.sample];
	[wc.window makeKeyAndOrderFront:nil];
}

@end
