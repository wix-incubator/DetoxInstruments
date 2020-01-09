//
//  DTXNetworkInspectorDataProvider.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXNetworkInspectorDataProvider.h"
#import "DTXInstrumentsModel.h"
#import "NSFormatter+PlotFormatters.h"
#import "NSColor+UIAdditions.h"
#import <CoreServices/CoreServices.h>
#import "NSString+FileNames.h"
#import "NSURL+UIAdditions.h"
#import "DTXRequestDocument.h"
#import "NSFont+UIAdditions.h"
#import "DTXFileInspectorContent.h"

@implementation DTXNetworkInspectorDataProvider
{
	NSURLResponse* _cachedURLResponse;
}

+ (BOOL)_hasImageWithMIMEType:(NSString*)MIMEType;
{
	if(MIMEType == nil)
	{
		return NO;
	}
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(MIMEType), NULL);
	
	BOOL rv = UTI != NULL ? UTTypeConformsTo(UTI, kUTTypeScalableVectorGraphics) == NO && UTTypeConformsTo(UTI, kUTTypeImage) : NO;
	
	if(UTI != NULL)
	{
		CFRelease(UTI);
	}
	
	return rv;
}

+ (BOOL)_hasTextWithMIMEType:(NSString*)MIMEType;
{
	if(MIMEType == nil)
	{
		return NO;
	}
	
	static NSRegularExpression* regex;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		regex = [[NSRegularExpression alloc] initWithPattern:@"javascript|json|html|text" options:NSRegularExpressionCaseInsensitive error:NULL];
	});
	
	if([regex matchesInString:MIMEType options:0 range:NSMakeRange(0, MIMEType.length)].count > 0)
	{
		return YES;
	}
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(MIMEType), NULL);
	
	BOOL rv = UTI != NULL ? UTTypeConformsTo(UTI, kUTTypeText) : NO;
	
	if(UTI != NULL)
	{
		CFRelease(UTI);
	}
	
	return rv;
}

+ (DTXInspectorContent*)inspctorContentForData:(NSData*)data response:(NSURLResponse*)response
{
	NSImage* image;
	NSView* customView;
	__block void (^customViewConstraintCreator)(NSView*) = nil;
	
	if([DTXNetworkInspectorDataProvider _hasImageWithMIMEType:response.MIMEType] && data)
	{
		NSImageView* rv = [DTXFileInspectorContent previewImageView];
		rv.image = [[NSImage alloc] initWithData:data];
		customView = rv;
	}
	else if([DTXNetworkInspectorDataProvider _hasTextWithMIMEType:response.MIMEType] && data)
	{
		NSString* string;
		if(response.textEncodingName)
		{
			CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding(CF(response.textEncodingName));
			NSStringEncoding targetEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
			string = [[NSString alloc] initWithData:data encoding:targetEncoding];
		}
		else
		{
			[NSString stringEncodingForData:data encodingOptions:@{NSStringEncodingDetectionSuggestedEncodingsKey: @[@(NSUTF8StringEncoding)]} convertedString:&string usedLossyConversion:NULL];
		}
		
		if(string != nil)
		{
			NSScrollView* rv = [NSScrollView new];

			rv.hasVerticalScroller = YES;
			rv.borderType = NSBezelBorder;

			NSTextView* tv = [NSTextView new];
			tv.font = [NSFont dtx_monospacedSystemFontOfSize:NSFont.systemFontSize weight:NSFontWeightRegular];
			tv.autoresizingMask = NSViewWidthSizable;
			tv.verticallyResizable = YES;
			tv.textContainer.widthTracksTextView = YES;
			tv.layoutManager.limitsLayoutForSuspiciousContents = NO;
			tv.layoutManager.allowsNonContiguousLayout = YES;
			tv.usesFindBar = YES;
			tv.editable = NO;

			tv.string = string;
			rv.documentView = tv;
			customView = rv;
		}
	}
	
	if(customView)
	{
		customViewConstraintCreator = ^ (NSView* view) {
			CGFloat constant = 200;
			if([view.subviews.firstObject isKindOfClass:NSImageView.class])
			{
				constant = MIN([view.subviews.firstObject image].size.height, constant);
			}
			[NSLayoutConstraint activateConstraints:@[
				[view.heightAnchor constraintEqualToConstant:constant],
			]];
		};
	}
	
	if(customView == nil)
	{
		if(response.MIMEType && data)
		{
			NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(response.MIMEType), NULL));
			image = [[NSWorkspace sharedWorkspace] iconForFileType:UTI];
			image.size = NSMakeSize(128, 128);
		}
	}
	
	if(image != nil || customView != nil)
	{
		DTXFileInspectorContent* responsePreview = [DTXFileInspectorContent new];
		
		responsePreview.image = image;
		[responsePreview setContentView:customView];
		if(customViewConstraintCreator)
		{
			customViewConstraintCreator(responsePreview.customView);
		}
		
		responsePreview.fileName = [self fileNameBestEffortWithResponse:response];
		responsePreview.title = responsePreview.fileName;
		responsePreview.data = data;
		
		return responsePreview;
	}
	
	//TODO: invert
	return nil;
}

+ (NSString *)fileNameBestEffortWithResponse:(NSURLResponse *)response
{
	NSString* fileName = response.suggestedFilename;
	
	if(fileName.length == 0)
	{
		fileName = response.URL.lastPathComponent;
		
		if(fileName.length == 0)
		{
			fileName = @"file";
		}
		
		NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(response.MIMEType), NULL));
		NSString* extension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(CF(UTI), kUTTagClassFilenameExtension));
		
		if(extension && [fileName.pathExtension isEqualToString:extension] == NO)
		{
			fileName = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
		}
		
		fileName = fileName.stringBySanitizingForFileName;
	}
	
	return fileName;
}

- (DTXInspectorContentTableDataSource*)inspectorTableDataSource
{
	NSMutableArray* contentArray = [NSMutableArray new];
	
	DTXNetworkSample* networkSample = self.networkSample;
	
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
		
		DTXInspectorContent* responsePreview = [DTXNetworkInspectorDataProvider inspctorContentForData:networkSample.responseData.data response:self._response];
		
		if(responsePreview)
		{
			responsePreview.title = NSLocalizedString(@"Response Preview", @"");
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

-(DTXNetworkSample*)networkSample
{
	return (id)self.sample;
}

- (NSURLResponse*)_response
{
	if(_cachedURLResponse == nil)
	{
		_cachedURLResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:self.networkSample.url] statusCode:self.networkSample.responseStatusCode HTTPVersion:@"2.0" headerFields:self.networkSample.responseHeaders];
	}
	
	return _cachedURLResponse;
}

- (BOOL)canSaveAs
{
	return YES;
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	[DTXFileInspectorContent saveData:self.networkSample.responseData.data fileName:[DTXNetworkInspectorDataProvider fileNameBestEffortWithResponse:self._response] inWindow:window];
}

- (BOOL)canCopyInView:(__kindof NSView *)view
{
	return [DTXNetworkInspectorDataProvider _hasImageWithMIMEType:self.networkSample.responseMIMEType];
}

- (void)copyInView:(__kindof NSView *)view sender:(id)sender
{
	if(self.networkSample.responseDataLength == 0)
	{
		return;
	}
	
	if([DTXNetworkInspectorDataProvider _hasImageWithMIMEType:self.networkSample.responseMIMEType])
	{
		NSImage* image = [[NSImage alloc] initWithData:self.networkSample.responseData.data];
		
		[[NSPasteboard generalPasteboard] clearContents];
		[[NSPasteboard generalPasteboard] writeObjects:@[image]];
	}
}

- (IBAction)openInRequestsPlayground:(id)sender
{
	DTXRequestDocument* requestDocument = [DTXRequestDocument new];
	[requestDocument loadRequestDetailsFromNetworkSample:self.sample document:self.document];
	[NSDocumentController.sharedDocumentController addDocument:requestDocument];
	[requestDocument makeWindowControllers];
	[requestDocument showWindows];
}

@end
