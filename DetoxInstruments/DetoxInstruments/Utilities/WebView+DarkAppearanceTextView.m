//
//  WebView+DarkAppearanceTextView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/24/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "WebView+DarkAppearanceTextView.h"
@import ObjectiveC;

//For the WebView stuff
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface _DTXSparkleWebTextViewScrollView : NSScrollView

@property (nonatomic, copy) NSString *preferencesIdentifier;
@property (nonatomic, strong) WebPreferences *preferences;
@property (nonatomic, assign) id <WebFrameLoadDelegate> frameLoadDelegate;
@property (nonatomic, assign) id <WebPolicyDelegate> policyDelegate;

@property (nonatomic, strong) NSTextView* webTextView;

@end

@interface _DTXFakeFrame : NSObject
{
	__weak _DTXSparkleWebTextViewScrollView* _webTextView;
}

- (instancetype)initWithWebTextView:(_DTXSparkleWebTextViewScrollView*)webTextView;

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL;

@end

@implementation _DTXFakeFrame

- (instancetype)initWithWebTextView:(_DTXSparkleWebTextViewScrollView *)webTextView
{
	self = [super init];
	
	if(self)
	{
		_webTextView = webTextView;
	}
	
	return self;
}

- (id)parentFrame
{
	return nil;
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL
{
	NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentOption: NSHTMLTextDocumentType, NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding), NSTextSizeMultiplierDocumentOption: @1.05} documentAttributes:nil error:NULL];
	[str addAttributes:@{NSForegroundColorAttributeName: NSColor.textColor} range:NSMakeRange(0, str.length)];
	
	[_webTextView.webTextView.textStorage appendAttributedString:str];
	[_webTextView.frameLoadDelegate webView:(id)_webTextView didFinishLoadForFrame:(id)self];
}

@end

@implementation _DTXSparkleWebTextViewScrollView

- (id)mainFrame
{
	return [[_DTXFakeFrame alloc] initWithWebTextView:self];;
}

- (void)stopLoading:(id)sender
{

}

@end

@implementation WebView (DarkAppearanceTextView)

- (instancetype)_initWithCoder_dtx:(NSCoder *)decoder
{
	_DTXSparkleWebTextViewScrollView* scrollView = [[_DTXSparkleWebTextViewScrollView alloc] initWithCoder:decoder];
	scrollView.contentView = [NSClipView new];
	NSSize contentSize = scrollView.frame.size;
	
	scrollView.borderType = NSNoBorder;
	scrollView.hasVerticalScroller = YES;
	scrollView.hasHorizontalScroller = NO;
	
	scrollView.preferences = WebPreferences.standardPreferences;
	
	scrollView.webTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	scrollView.webTextView.minSize = NSMakeSize(0.0, contentSize.height);
	scrollView.webTextView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
	scrollView.webTextView.verticallyResizable = YES;
	scrollView.webTextView.horizontallyResizable = NO;
	scrollView.webTextView.autoresizingMask = NSViewWidthSizable;
	scrollView.webTextView.textContainer.containerSize = NSMakeSize(contentSize.width, FLT_MAX);
	scrollView.webTextView.textContainer.widthTracksTextView = YES;
	scrollView.webTextView.textContainerInset = NSMakeSize(0, 10);
	
	scrollView.webTextView.editable = NO;
	scrollView.webTextView.font = [NSFont systemFontOfSize:NSFont.systemFontSize];

	scrollView.documentView = scrollView.webTextView;

	return (id)scrollView;
}

@end
