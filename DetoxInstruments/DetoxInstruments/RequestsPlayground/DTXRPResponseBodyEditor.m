//
//  DTXRPResponseBodyEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/10/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXRPResponseBodyEditor.h"
#import "DTXInspectorContentTableDataSource.h"
#import "NSColor+UIAdditions.h"
#import "NSURL+UIAdditions.h"
#import "NSString+FileNames.h"

@interface DTXRPResponseBodyEditor ()
{
	IBOutlet NSTableView* _tableView;
	DTXInspectorContentTableDataSource* _tableDataSource;
	
	NSURLResponse* _response;
	NSData* _body;
	NSError* _error;
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
	NSImage* image;
	if(self._hasImage && _body != nil)
	{
		image = [[NSImage alloc] initWithData:_body];
	}
	else
	{
		if(_response.MIMEType && _body != nil)
		{
			NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(_response.MIMEType), NULL));
			image = [[NSWorkspace sharedWorkspace] iconForFileType:UTI];
			image.size = NSMakeSize(128, 128);
		}
	}
	
	if(image)
	{
		DTXInspectorContent* responsePreview = [DTXInspectorContent new];
		responsePreview.title = self._bestGuessFileName;
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
		
		_tableDataSource.contentArray = @[responsePreview];
	}
	else if(_error != nil)
	{
		DTXInspectorContent* responsePreview = [DTXInspectorContent new];
		responsePreview.title = NSLocalizedString(@"Error", @"");
		responsePreview.content = @[[DTXInspectorContentRow contentRowWithTitle:nil description:_error.localizedFailureReason ?: _error.localizedDescription]];
		_tableDataSource.contentArray = @[responsePreview];
	}
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

- (void)setBody:(NSData *)body response:(NSURLResponse*)response error:(NSError*)error
{
	_body = body;
	_response = response;
	_error = error;
	[self _reloadTable];
}

@end
