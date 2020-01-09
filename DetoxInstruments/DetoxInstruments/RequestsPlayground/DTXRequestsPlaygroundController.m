//
//  DTXRequestsPlaygroundController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/3/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRequestsPlaygroundController.h"
#import "DTXTabViewItem.h"
#import "DTXRPCookiesEditor.h"
#import "DTXRequestHeadersEditor.h"
#import "DTXRPQueryStringEditor.h"
#import "DTXRPBodyEditor.h"
#import "DTXRPResponseBodyEditor.h"
#import "DTXRPCurlSnippetExporter.h"
#import "DTXRPNodeSnippetExporter.h"

static NSString* const __codeSnippetKey = @"DTXRequestsPlaygroundController.codeSnippet";

@interface NSSegmentedCell ()

- (void)_trackSelectedItemMenu;

@end

@interface DTXRequestsPlaygroundController () <NSTabViewDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, copy) NSString* method;
@property (nonatomic, copy) NSString* address;
@property (nonatomic, copy) id cookiesFromEditor;
@property (nonatomic, copy) id contentTypeFromEditor;
@property (nonatomic, copy) id headersFromEditor;

@end

@implementation DTXRequestsPlaygroundController
{
	BOOL _loading;
	
	IBOutlet NSTabView* _tabView;
	IBOutlet DTXTabViewItem* _headersTabViewItem;
	IBOutlet DTXTabViewItem* _cookiesTabViewItem;
	IBOutlet DTXTabViewItem* _queryTabViewItem;
	IBOutlet DTXTabViewItem* _bodyTabViewItem;
	IBOutlet DTXTabViewItem* _responseBodyTabViewItem;
	
	IBOutlet NSProgressIndicator* _progressIndicator;
	IBOutlet NSImageView* _errorIndicator;
	
	IBOutlet NSSegmentedControl* _copyCodeSegmentedControl;
	IBOutlet NSMenu* _copyCodeMenu;
	
	DTXRPQueryStringEditor* _queryStringEditor;
	DTXRequestHeadersEditor* _headersEditor;
	DTXRPCookiesEditor* _cookiesEditor;
	DTXRPBodyEditor* _bodyEditor;
	DTXRPResponseBodyEditor* _responseEditor;
	
	DTXNetworkSample* _cachedNetworkSample;
	NSURLRequest* _cachedURLRequest;
	
	NSURLSession* _urlSession;
	NSURLSessionDataTask* _dataTask;
	NSURLSessionTaskMetrics* _pendingMetrics;
	
	IBOutlet NSSegmentedControl* _touchBarSegmentedControl;
}

@dynamic cookiesFromEditor, contentTypeFromEditor, headersFromEditor;

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_loading = YES;
	self.method = @"GET";
	self.address = @"";
	_loading = NO;
}

- (void)setAddress:(NSString *)address
{
	if([_address isEqualToString:address] == NO)
	{
		_address = address;
		_queryStringEditor.address = _address;
		if(_loading == NO)
		{
			[self.view.window.windowController.document updateChangeCount:NSChangeDone];
		}
	}
}

- (void)setMethod:(NSString *)method
{
	if([_method isEqualToString:method] == NO)
	{
		_method = method;
		if(_loading == NO)
		{
			[self.view.window.windowController.document updateChangeCount:NSChangeDone];
		}
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_progressIndicator.usesThreadedAnimation = YES;
	
	[_copyCodeSegmentedControl setMenu:_copyCodeMenu forSegment:1];
	
	[self _setResponseTabViewItemsEnabled:NO switchToBodyTab:NO];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	_headersEditor = (id)[_headersTabViewItem.view viewWithTag:100].nextResponder;
	_cookiesEditor = (id)[_cookiesTabViewItem.view viewWithTag:100].nextResponder;
	_queryStringEditor = (id)[_queryTabViewItem.view viewWithTag:100].nextResponder;
	_bodyEditor = (id)[_bodyTabViewItem.view viewWithTag:100].nextResponder;
	_responseEditor = (id)[_responseBodyTabViewItem.view viewWithTag:100].nextResponder;
	
	if(_cachedNetworkSample)
	{
		[self loadRequestDetailsFromNetworkSample:_cachedNetworkSample];
		_cachedNetworkSample = nil;
	}
	else if(_cachedURLRequest)
	{
		[self loadRequestDetailsFromURLRequest:_cachedURLRequest];
		_cachedURLRequest = nil;
	}
	
	[self bind:@"address" toObject:_queryStringEditor withKeyPath:@"address" options:nil];
	
	[self _synchronizeTabViewToTouchBar];
}

- (void)loadRequestDetailsFromNetworkSample:(DTXNetworkSample*)networkSample
{
	if(_headersEditor == nil)
	{
		_cachedNetworkSample = networkSample;
		return;
	}
	
	_loading = YES;
	self.method = networkSample.requestHTTPMethod;
	self.address = networkSample.url;
	
	_headersEditor.requestHeaders = networkSample.requestHeaders;
	_queryStringEditor.address = self.address;
	[_bodyEditor setBody:networkSample.requestData.data withContentType:networkSample.requestHeaders[@"Content-Type"]];
	
	[self _sharedFinishLoading];
	
	_loading = NO;
}

- (void)loadRequestDetailsFromURLRequest:(NSURLRequest*)request
{
	if(_headersEditor == nil)
	{
		_cachedURLRequest = request;
		return;
	}
	
	_loading = YES;
	self.method = request.HTTPMethod ?: @"GET";
	self.address = request.URL.absoluteString ?: @"";
	
	_headersEditor.requestHeaders = request.allHTTPHeaderFields ?: @{};
	_queryStringEditor.address = self.address;
	[_bodyEditor setBody:request.HTTPBody withContentType:request.allHTTPHeaderFields[@"Content-Type"]];
	
	[self _sharedFinishLoading];
	
	_loading = NO;
}

- (void)_updateHeader:(NSString*)header withValue:(NSString*)value
{
	NSMutableDictionary* newHeaders = _headersEditor.requestHeaders.mutableCopy;
	if(value != nil)
	{
		newHeaders[header] = value;
	}
	else
	{
		[newHeaders removeObjectForKey:header];
	}
	
	_headersEditor.requestHeaders = newHeaders;
}

- (id)cookiesFromEditor
{
	return nil;
}

- (void)setCookiesFromEditor:(NSDictionary*)cookiesFromEditor
{
	if([[self _cookiesFromHeaders:_headersEditor.requestHeaders] isEqualToDictionary:cookiesFromEditor])
	{
		return;
	}
	
	if(cookiesFromEditor.count > 0)
	{
		NSMutableString* cookies = [NSMutableString new];
		[cookiesFromEditor enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
			[cookies appendFormat:@"%@=%@;", key, obj];
		}];
		[self _updateHeader:@"Cookie" withValue:cookies];
	}
	else
	{
		[self _updateHeader:@"Cookie" withValue:nil];
	}
}

- (id)contentTypeFromEditor
{
	return nil;
}

- (void)setContentTypeFromEditor:(NSString*)contentTypeFromEditor
{
	if(contentTypeFromEditor.length == 0)
	{
		contentTypeFromEditor = nil;
	}
	
	[self _updateHeader:@"Content-Type" withValue:contentTypeFromEditor];
}

- (id)headersFromEditor
{
	return nil;
}

- (NSDictionary*)_cookiesFromHeaders:(NSDictionary*)headers
{
	NSArray* splitCookies = [headers[@"Cookie"] componentsSeparatedByString:@";"];
	NSMutableDictionary* cookies = [NSMutableDictionary new];
	[splitCookies enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSArray<NSString*>* components = [obj componentsSeparatedByString:@"="];
		NSString* key = components.firstObject.stringByTrimmingWhiteSpace;
		NSString* value = components.count < 2 ? @"" : components.lastObject.stringByTrimmingWhiteSpace;
		if(value.length > 0 || key.length > 0)
		{
			[cookies setValue:value forKey:key];
		}
	}];
	return cookies;
}

- (void)setHeadersFromEditor:(NSDictionary*)headersFromEditor
{
	NSDictionary* cookies = [self _cookiesFromHeaders:headersFromEditor];
	
	NSString* contentType = headersFromEditor[@"Content-Type"];
	
	if(_cookiesEditor.cookies == nil || [_cookiesEditor.cookies isEqualToDictionary:cookies] == NO)
	{
		_cookiesEditor.cookies = cookies;
	}
	if(_bodyEditor.contentType == nil || [_bodyEditor.contentType isEqualToString:contentType] == NO)
	{
		_bodyEditor.contentType = contentType;
	}
}

- (void)_sharedFinishLoading
{
	[self bind:@"headersFromEditor" toObject:_headersEditor withKeyPath:@"requestHeaders" options:nil];
	[self bind:@"cookiesFromEditor" toObject:_cookiesEditor withKeyPath:@"cookies" options:nil];
	[self bind:@"contentTypeFromEditor" toObject:_bodyEditor withKeyPath:@"contentType" options:nil];
}

- (NSURLRequest*)_requestFromData
{
	NSMutableURLRequest* rv = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.address]];
	rv.HTTPShouldHandleCookies = NO;
	rv.allHTTPHeaderFields = _headersEditor.requestHeaders;
	rv.HTTPBody = _bodyEditor.body;
	rv.HTTPMethod = self.method;
	return rv;
}

- (NSURLRequest*)requestForSaving
{
	return self._requestFromData;
}

- (void)_updateProgressIndicator
{
	if(_progressIndicator.doubleValue == 0)
	{
		[_progressIndicator stopAnimation:nil];
	}
	else
	{
		[_progressIndicator startAnimation:nil];
	}
}

- (void)_setResponseTabViewItemsEnabled:(BOOL)enabled switchToBodyTab:(BOOL)switchToBody
{
	_responseBodyTabViewItem.enabled = enabled;
	[_touchBarSegmentedControl setEnabled:enabled forSegment:_touchBarSegmentedControl.segmentCount - 1];
	
//	if((_responseHeadersTabViewItem.enabled == NO && _responseHeadersTabViewItem.tabState == NSSelectedTab) ||
//	   (_responseBodyTabViewItem.enabled == NO && _responseBodyTabViewItem.tabState == NSSelectedTab))
//	{
//		[_tabView selectTabViewItem:_headersTabViewItem];
//	}
	
	if(switchToBody)
	{
		[_tabView selectTabViewItem:_responseBodyTabViewItem];
	}
}

- (IBAction)sendRequest:(id)sender
{
	NSURLSessionConfiguration* config = NSURLSessionConfiguration.defaultSessionConfiguration;
	config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	config.URLCache = nil;
	_urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:NSOperationQueue.mainQueue];
	
	NSURLRequest* request = self._requestFromData;
	
	if(_dataTask != nil)
	{
		[_dataTask cancel];
	}
	
	_errorIndicator.hidden = YES;
	
	[self _setResponseTabViewItemsEnabled:NO switchToBodyTab:NO];
	
	_progressIndicator.doubleValue += 1;
	_dataTask = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_progressIndicator.doubleValue -= 1;
			[self _updateProgressIndicator];
			
			if(error != nil && error.code == NSURLErrorCancelled)
			{
				[self _setResponseTabViewItemsEnabled:NO switchToBodyTab:NO];
				return;
			}
			
			NSUInteger statusCode = 0;
			if([response isKindOfClass:NSHTTPURLResponse.class])
			{
				statusCode = [(NSHTTPURLResponse*)response statusCode];
			}
			
			if(error != nil || statusCode >= 400)
			{
				_errorIndicator.hidden = NO;
			}

			[_responseEditor setBody:data response:response error:error metrics:_pendingMetrics];
			[self _setResponseTabViewItemsEnabled:YES switchToBodyTab:YES];
			
			_dataTask = nil;
			_pendingMetrics = nil;
		});
	}];
	
	[self _updateProgressIndicator];
	[_dataTask resume];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	menuItem.state = [NSUserDefaults.standardUserDefaults integerForKey:__codeSnippetKey] == menuItem.tag ? NSControlStateValueOn : NSControlStateValueOff;
	
	return YES;
}

- (IBAction)setCodeSnippedLanguage:(NSMenuItem*)sender
{
	[NSUserDefaults.standardUserDefaults setInteger:sender.tag forKey:__codeSnippetKey];
}

- (void)_copyCodeSnippet
{
	NSInteger snippetLanguage = [NSUserDefaults.standardUserDefaults integerForKey:__codeSnippetKey];
	Class exporterClass;
	
	switch (snippetLanguage) {
		case 0:
			exporterClass = [DTXRPCurlSnippetExporter class];
			break;
		case 1:
			exporterClass = [DTXRPNodeSnippetExporter class];
			break;
	}
	
	NSString* snippet = [exporterClass snippetWithRequest:self._requestFromData];
	[NSPasteboard.generalPasteboard clearContents];
	[NSPasteboard.generalPasteboard setString:snippet forType:NSPasteboardTypeString];
}

- (IBAction)copyCodeSnippet:(NSSegmentedControl*)sender
{
	if(sender.selectedSegment != 0)
	{
		[sender.cell _trackSelectedItemMenu];
		
		return;
	}
	
	[self _copyCodeSnippet];
}

- (void)_synchronizeTabViewToTouchBar
{
	_touchBarSegmentedControl.selectedSegment = [self.tabView.selectedTabViewItem.identifier integerValue];
}

- (IBAction)_touchBarSegmentedControlAction:(NSSegmentedControl*)sender
{
	[self.tabView selectTabViewItem:self.tabView.tabViewItems[sender.selectedSegment]];
}

- (NSTouchBar *)makeTouchBar
{
	return _touchBar;
}

#pragma mark NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{	
	if(self.view.window.firstResponder == self.view.window)
	{
		[self.view.window makeFirstResponder:self.view];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
	[self _synchronizeTabViewToTouchBar];
	
	if([self.view.window.firstResponder isKindOfClass:NSView.class] && [(NSView*)self.view.window.firstResponder isHiddenOrHasHiddenAncestor])
	{
		[self.view.window makeFirstResponder:self.view];
	}
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
	_pendingMetrics = metrics;
}

@end
