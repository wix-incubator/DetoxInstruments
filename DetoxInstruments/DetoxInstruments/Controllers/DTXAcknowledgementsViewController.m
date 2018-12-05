//
//  DTXAcknowledgementsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/26/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXAcknowledgementsViewController.h"
@import WebKit;

@interface DTXAcknowledgementsViewController () <WKNavigationDelegate> @end

@implementation DTXAcknowledgementsViewController
{
//	IBOutlet __weak WKWebView* _webView;
	IBOutlet __weak NSTextView* _textView;
	NSURL* _htmlURL;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_htmlURL = [[NSBundle mainBundle] URLForResource:@"Acknowledgements" withExtension:@"html"];
	
	NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithData:[NSData dataWithContentsOfURL:_htmlURL] options:@{NSDocumentTypeDocumentOption: NSHTMLTextDocumentType, NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding)} documentAttributes:nil error:NULL];
	[str addAttributes:@{NSForegroundColorAttributeName: NSColor.textColor} range:NSMakeRange(0, str.length)];
	
	[str enumerateAttributesInRange:NSMakeRange(0, str.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
		NSLog(@"%@", attrs);
	}];
	
	[_textView.textStorage appendAttributedString:str];
	_textView.textContainerInset = NSMakeSize(20, 20);
}

@end
