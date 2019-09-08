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
#import "DTXRequestDocument.h"
#import "NSFont+UIAdditions.h"
#import "DTXExpandedPreviewWindowController.h"
#import "DTXPreviewContainerView.h"

static void _DTXSaveData(NSData* data, NSString* fileName, NSWindow* window)
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setNameFieldStringValue:fileName];
	
	[panel beginSheetModalForWindow:window completionHandler:^ (NSInteger result) {
		if (result == NSModalResponseOK)
		{
			NSURL* theFile = [panel URL];
			
			[data writeToURL:theFile atomically:YES];
		}
	}];
}

static NSImageView* _DTXPreviewImageView(void)
{
	NSImageView* rv = [NSImageView new];
	rv.translatesAutoresizingMaskIntoConstraints = NO;
	rv.imageScaling = NSImageScaleProportionallyUpOrDown;
	[rv setContentCompressionResistancePriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationHorizontal];
	[rv setContentCompressionResistancePriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationHorizontal];
	[rv setContentCompressionResistancePriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationVertical];
	[rv setContentCompressionResistancePriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationVertical];
	[rv setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationHorizontal];
	[rv setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationHorizontal];
	[rv setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationVertical];
	[rv setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression forOrientation:NSLayoutConstraintOrientationVertical];
	return rv;
}

@interface DTXFileInspectorContent : DTXInspectorContent

@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, strong) NSButton* expandCloseButton;

@end

@implementation DTXFileInspectorContent
{
	DTXExpandedPreviewWindowController* _expandedPreviewWindowController;
	DTXPreviewContainerView* _previewContainer;
	__kindof NSView* _customView;
}

- (void)_setupButtonForExpansion
{
	_expandCloseButton.bezelStyle = NSBezelStyleRounded;
	_expandCloseButton.image = [NSImage imageNamed:@"expand_preview"];
	_expandCloseButton.imagePosition = NSImageOnly;
	_expandCloseButton.imageScaling = NSImageScaleNone;
	_expandCloseButton.target = self;
	_expandCloseButton.action = @selector(expandPreview:);
	_expandCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)_setupButtonForClose
{
	_expandCloseButton.bezelStyle = NSBezelStyleRounded;
	_expandCloseButton.image = [NSImage imageNamed:@"close_preview"];
	_expandCloseButton.imagePosition = NSImageOnly;
	_expandCloseButton.imageScaling = NSImageScaleNone;
	_expandCloseButton.target = self;
	_expandCloseButton.action = @selector(closePreview:);
	_expandCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)_constraintContentView:(NSView*)contentView inConainer:(NSView*)containerView insets:(NSEdgeInsets)insets center:(BOOL)center
{
	NSLayoutConstraint* leading = [containerView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:insets.left];
	leading.priority = center ? NSLayoutPriorityDefaultLow : NSLayoutPriorityRequired;
	NSLayoutConstraint* trailing = [containerView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:insets.right];
	trailing.priority = center ? NSLayoutPriorityDefaultLow : NSLayoutPriorityRequired;
	
	[NSLayoutConstraint activateConstraints:@[
		leading,
		trailing,
		[containerView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:insets.top],
		[containerView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:insets.bottom],
	]];
	
	if(center)
	{
		[containerView.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor].active = YES;
	}
}

- (void)_setContentView:(NSView*)contentView
{
	[_customView removeFromSuperview];
	_customView = nil;
	
	if(contentView == nil)
	{
		return;
	}
	
	_customView = contentView;
	_customView.wantsLayer = YES;
	_customView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	if([_customView isKindOfClass:NSScrollView.class])
	{
		NSView* doc = ((NSScrollView*)_customView).documentView;
		doc.wantsLayer = YES;
		doc.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	}
	_customView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.customView addSubview:_customView];
	
	[self _constraintContentView:_customView inConainer:self.customView insets:NSEdgeInsetsZero center:NO];
}

- (NSView *)customView
{
	if(_customView == nil)
	{
		return nil;
	}
	
	if(_previewContainer == nil)
	{
		_previewContainer = [DTXPreviewContainerView new];
		_previewContainer.wantsLayer = YES;
		_previewContainer.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
		_previewContainer.translatesAutoresizingMaskIntoConstraints = NO;
//		_previewContainer.material = NSVisualEffectMaterialHUDWindow;
		
		[self _setupButtonForExpansion];
	}
	
	return _previewContainer;
}

- (NSURL*)_prepareTempFile
{
	NSURL* target = [NSURL.temporaryDirectoryURL URLByAppendingPathComponent:self.fileName];
	
	[self.data writeToURL:target atomically:YES];
	
	return target;
}

- (IBAction)saveAs:(id)sender
{
	[self saveAs:sender inWindow:[sender window]];
}

- (IBAction)share:(id)sender
{
	NSSharingServicePicker* picker = [[NSSharingServicePicker alloc] initWithItems:@[self._prepareTempFile]];
	[picker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMinY];
}

- (IBAction)open:(id)sender
{
	if(_expandedPreviewWindowController != nil)
	{
		[self closePreview:nil];
	}
	
	NSURL* target = self._prepareTempFile;
	
	[NSWorkspace.sharedWorkspace openURL:target];
}

- (void)saveAs:(id)sender inWindow:(NSWindow*)window
{
	_DTXSaveData(self.data, self.fileName, window);
}

- (NSRect)_frameForClosedExpandedPreviewWithWindow:(NSWindow*)window view:(NSView*)view
{
	if(_customView.window == nil)
	{
		return NSZeroRect;
	}
	
	NSRect frameInWindow = [view convertRect:view.bounds toView:nil];
	NSRect frameInScreen = [view.window convertRectToScreen:frameInWindow];
	frameInScreen = [window frameRectForContentRect:NSMakeRect(frameInScreen.origin.x - 3, frameInScreen.origin.y - 3, frameInScreen.size.width + 6, frameInScreen.size.height + 3)];
	
	return NSMakeRect(frameInScreen.origin.x, frameInScreen.origin.y, frameInScreen.size.width, frameInScreen.size.height);
}

- (NSRect)_imageViewFrameForClosedExpandedPreviewWithWindow:(NSWindow*)window
{
	return [self _frameForClosedExpandedPreviewWithWindow:window view:_customView.subviews.firstObject];
}

- (NSRect)_viewFrameForClosedExpandedPreviewWithWindow:(NSWindow*)window
{
	return [self _frameForClosedExpandedPreviewWithWindow:window view:_previewContainer];
}

- (NSRect)_frameForOpenExpandedPreview
{
	NSRect visibleFrame = _previewContainer.window.screen.visibleFrame;
	NSRect rv = NSMakeRect(0, 0, visibleFrame.size.width / 1.5, visibleFrame.size.height / 1.5);
	rv.origin = NSMakePoint(CGRectGetMidX(visibleFrame) - rv.size.width / 2, CGRectGetMidY(visibleFrame) - rv.size.height / 2);
	
	return rv;
}

- (void)_closeNoAnchor:(id)sender completion:(void(^)(void))completionHandler
{
	_expandedPreviewWindowController.window.animationBehavior = NSWindowAnimationBehaviorUtilityWindow;
	completionHandler();
}

- (void)closePreview:(id)sender
{
	[_expandedPreviewWindowController.window orderFront:sender];
	
	void (^completion)(void) = ^ {
		if(_previewContainer.window.isMiniaturized == NO)
		{
			[_previewContainer.window orderWindow:NSWindowBelow relativeTo:_expandedPreviewWindowController.window.windowNumber];
		}
		
		[_expandedPreviewWindowController close];
		_expandedPreviewWindowController = nil;
		
		if([_customView isKindOfClass:NSImageView.class] == NO)
		{
			[_customView removeFromSuperview];
			[_previewContainer addSubview:_customView];
			[self _constraintContentView:_customView inConainer:_previewContainer insets:NSEdgeInsetsZero center:NO];
			[_previewContainer layoutSubtreeIfNeeded];
		}
		else
		{
			_customView.alphaValue = 1.0;
		}
		
		[self _setupButtonForExpansion];
	};
	
	if(_previewContainer.window == nil || _previewContainer.window.isMiniaturized == YES)
	{
		[self _closeNoAnchor:sender completion:completion];
		
		return;
	}
	
	NSRect targetRect;
	if([_customView isKindOfClass:NSImageView.class] == NO)
	{
		targetRect = [self _viewFrameForClosedExpandedPreviewWithWindow:_expandedPreviewWindowController.window];
	}
	else
	{
		targetRect = [self _imageViewFrameForClosedExpandedPreviewWithWindow:_expandedPreviewWindowController.window];
	}
	
	[_expandedPreviewWindowController disappearanceAnimationWillStart];
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.25;
		context.allowsImplicitAnimation = YES;
		[_expandedPreviewWindowController animateDisappearance];
		[_expandedPreviewWindowController.window setFrame:targetRect display:YES animate:YES];
	} completionHandler:^{
		completion();
	}];
}

- (void)_setupExpansionForImageView
{
	_customView.alphaValue = 0.0;
	
	NSImageView* rv = _DTXPreviewImageView();
	rv.image = [_customView image];
	[_expandedPreviewWindowController.contentView addSubview:rv];
	[self _constraintContentView:rv inConainer:_expandedPreviewWindowController.contentView insets:NSEdgeInsetsMake(0, -3, 3, 3) center:NO];
}

- (void)_setupExpansionForView
{
	[_customView removeFromSuperview];
	[_expandedPreviewWindowController.window.contentViewController.view addSubview:_customView];
	[self _constraintContentView:_customView inConainer:_expandedPreviewWindowController.contentView insets:NSEdgeInsetsMake(0, -3, 3, 3) center:NO];
}

- (void)expandPreview:(id)sender
{
	if(_expandedPreviewWindowController != nil || _customView == nil)
	{
		return;
	}
	
	_expandedPreviewWindowController = [[NSStoryboard storyboardWithName:@"Profiler" bundle:nil] instantiateControllerWithIdentifier:@"PreviewExtendedWindowController"];
	_expandedPreviewWindowController.closeTarget = self;
	_expandedPreviewWindowController.action = @selector(closePreview:);
	
	NSRect sourceRect = [self _imageViewFrameForClosedExpandedPreviewWithWindow:_expandedPreviewWindowController.window];
	[_expandedPreviewWindowController.window setFrame:sourceRect display:NO];
	
	_expandedPreviewWindowController.openButton.target = self;
	_expandedPreviewWindowController.openButton.action = @selector(open:);
	_expandedPreviewWindowController.saveButton.target = self;
	_expandedPreviewWindowController.saveButton.action = @selector(saveAs:);
	[_expandedPreviewWindowController.shareButton sendActionOn:NSEventMaskLeftMouseDown];
	_expandedPreviewWindowController.shareButton.target = self;
	_expandedPreviewWindowController.shareButton.action = @selector(share:);
	_expandedPreviewWindowController.windowTitle = self.fileName;
	
	NSRect targetExpandedPreviewFrame = [self _frameForOpenExpandedPreview];
	
	if([_customView isKindOfClass:NSImageView.class])
	{
		[self _setupExpansionForImageView];
	}
	else
	{
		[self _setupExpansionForView];
	}
	
	[_expandedPreviewWindowController showWindow:nil];
	
//	NSTimeInterval animationDuration = [_expandedPreviewWindowController.window animationResizeTime:targetExpandedPreviewFrame];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.25;
		context.allowsImplicitAnimation = YES;
		[_expandedPreviewWindowController animateAppearance];
		[_expandedPreviewWindowController.window setFrame:targetExpandedPreviewFrame display:YES animate:YES];
		
		[self _setupButtonForClose];
	} completionHandler:^{
		[_expandedPreviewWindowController appearanceAnimationDidEnd];
	}];
}

@end

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
		NSImageView* rv = _DTXPreviewImageView();
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
		[responsePreview _setContentView:customView];
		if(customViewConstraintCreator)
		{
			customViewConstraintCreator(responsePreview.customView);
		}
		
		responsePreview.fileName = [self fileNameBestEffortWithResponse:response];
		responsePreview.title = responsePreview.fileName;
		responsePreview.data = data;
		
		responsePreview.expandCloseButton = [NSButton new];
		[responsePreview _setupButtonForExpansion];
		
		NSButton* previewButton = [NSButton new];
		previewButton.bezelStyle = NSBezelStyleRounded;
		previewButton.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
		previewButton.title = NSLocalizedString(@"Open", @"");
		previewButton.target = responsePreview;
		previewButton.action = @selector(open:);
		previewButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSButton* saveButton = [NSButton new];
		saveButton.bezelStyle = NSBezelStyleRounded;
		saveButton.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
		saveButton.title = NSLocalizedString(@"Save As…", @"");
		saveButton.target = responsePreview;
		saveButton.action = @selector(saveAs:);
		saveButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		NSButton* shareButton = [NSButton new];
		[shareButton sendActionOn:NSEventMaskLeftMouseDown];
		shareButton.bezelStyle = NSBezelStyleRounded;
		shareButton.image = [NSImage imageNamed:NSImageNameShareTemplate];
		shareButton.target = responsePreview;
		shareButton.action = @selector(share:);
		shareButton.translatesAutoresizingMaskIntoConstraints = NO;
		
		responsePreview.buttons = @[responsePreview.expandCloseButton, previewButton, saveButton, shareButton];
		
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
	_DTXSaveData(self.networkSample.responseData.data, [DTXNetworkInspectorDataProvider fileNameBestEffortWithResponse:self._response], window);
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
