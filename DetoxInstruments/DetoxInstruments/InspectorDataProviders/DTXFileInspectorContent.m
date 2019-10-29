//
//  DTXFileInspectorContent.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 9/9/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXFileInspectorContent.h"
#import "DTXExpandedPreviewWindowController.h"
#import "DTXPreviewContainerView.h"
#import "NSURL+UIAdditions.h"

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

@implementation DTXFileInspectorContent
{
	DTXExpandedPreviewWindowController* _expandedPreviewWindowController;
	DTXPreviewContainerView* _previewContainer;
	__kindof NSView* _customView;
}

+ (NSImageView*)previewImageView
{
	return _DTXPreviewImageView();
}

+ (void)saveData:(NSData*) data fileName:(NSString*)fileName inWindow:(NSWindow*)window
{
	_DTXSaveData(data, fileName, window);
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

- (void)setContentView:(NSView*)contentView
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
	
	self.expandCloseButton = [NSButton new];
	[self _setupButtonForExpansion];
	
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
	
	self.buttons = @[self.expandCloseButton, previewButton, saveButton, shareButton];
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

- (BOOL)expandPreview
{
	[self expandPreview:nil];
	
	return YES;
}

@end
