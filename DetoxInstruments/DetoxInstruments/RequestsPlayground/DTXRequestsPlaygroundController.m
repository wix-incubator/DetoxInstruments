//
//  DTXRequestsPlaygroundController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/3/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
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

@interface DTXRequestsPlaygroundController () <NSTabViewDelegate>

@property (nonatomic, copy) NSString* method;
@property (nonatomic, copy) NSString* address;
@property (nonatomic, copy) NSDictionary<NSString*, NSString*>* requestHeaders;

@end

@implementation DTXRequestsPlaygroundController
{
	BOOL _loading;
	
	IBOutlet DTXTabViewItem* _headersTabViewItem;
	IBOutlet DTXTabViewItem* _cookiesTabViewItem;
	IBOutlet DTXTabViewItem* _queryTabViewItem;
	IBOutlet DTXTabViewItem* _bodyTabViewItem;
	IBOutlet DTXTabViewItem* _responseHeadersTabViewItem;
	IBOutlet DTXTabViewItem* _responseBodyTabViewItem;
	
	IBOutlet NSProgressIndicator* _progressIndicator;
	IBOutlet NSImageView* _errorIndicator;
	
	IBOutlet NSSegmentedControl* _copyCodeSegmentedControl;
	IBOutlet NSMenu* _copyCodeMenu;
	
	DTXRPQueryStringEditor* _queryStringEditor;
	DTXRequestHeadersEditor* _headersEditor;
	DTXRPCookiesEditor* _cookiesEditor;
	DTXRPBodyEditor* _bodyEditor;
	DTXRequestHeadersEditor* _responseHeadersEditor;
	DTXRPResponseBodyEditor* _responseEditor;
	
	DTXNetworkSample* _cachedNetworkSample;
	NSURLRequest* _cachedURLRequest;
	
	NSURLSessionDataTask* _dataTask;
}

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
		[self willChangeValueForKey:@"address"];
		_address = address;
		_queryStringEditor.address = _address;
		if(_loading == NO)
		{
			[self.view.window.windowController.document updateChangeCount:NSChangeDone];
		}
		[self didChangeValueForKey:@"address"];
	}
}

- (void)setMethod:(NSString *)method
{
	if([_method isEqualToString:method] == NO)
	{
		[self willChangeValueForKey:@"method"];
		_method = method;
		if(_loading == NO)
		{
			[self.view.window.windowController.document updateChangeCount:NSChangeDone];
		}
		[self didChangeValueForKey:@"method"];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_progressIndicator.usesThreadedAnimation = YES;
	
	[_copyCodeSegmentedControl setMenu:_copyCodeMenu forSegment:1];
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	_headersEditor = (id)[_headersTabViewItem.view viewWithTag:100].nextResponder;
	_cookiesEditor = (id)[_cookiesTabViewItem.view viewWithTag:100].nextResponder;
	_queryStringEditor = (id)[_queryTabViewItem.view viewWithTag:100].nextResponder;
	_bodyEditor = (id)[_bodyTabViewItem.view viewWithTag:100].nextResponder;
	_responseHeadersEditor = (id)[_responseHeadersTabViewItem.view viewWithTag:100].nextResponder;
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
	self.requestHeaders = networkSample.requestHeaders;
	
	_headersEditor.requestHeaders = self.requestHeaders;
	_queryStringEditor.address = self.address;
	_bodyEditor.body = networkSample.requestData.data;
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
	self.requestHeaders = request.allHTTPHeaderFields ?: @{};
	
	_headersEditor.requestHeaders = self.requestHeaders;
	_queryStringEditor.address = self.address;
	_bodyEditor.body = request.HTTPBody;
	_loading = NO;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
	if(_headersTabViewItem.tabState == NSSelectedTab)
	{
		self.requestHeaders = _headersEditor.requestHeaders;
		NSArray* splitCookies = [self.requestHeaders[@"Cookie"] componentsSeparatedByString:@";"];
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
		_cookiesEditor.cookies = cookies;
	}
	if(_cookiesTabViewItem.tabState == NSSelectedTab)
	{
		NSMutableString* cookies = [NSMutableString new];
		NSMutableDictionary* newHeaders = self.requestHeaders.mutableCopy;
		if(_cookiesEditor.cookies.count > 0)
		{
			[_cookiesEditor.cookies enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
				[cookies appendFormat:@"%@=%@; ", key, obj];
			}];
			newHeaders[@"Cookie"] = cookies;
		}
		else
		{
			[newHeaders removeObjectForKey:@"Cookie"];
		}
		
		self.requestHeaders = newHeaders;
		_headersEditor.requestHeaders = newHeaders;
	}
}

- (NSURLRequest*)_requestFromData
{
	[self.view.window makeFirstResponder:self.view];
	
	NSMutableURLRequest* rv = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.address]];
	rv.HTTPShouldHandleCookies = NO;
	rv.allHTTPHeaderFields = self.requestHeaders;
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

- (void)_setResponseTabViewItemsEnabled:(BOOL)enabled
{
	_responseHeadersTabViewItem.enabled = enabled;
	_responseBodyTabViewItem.enabled = enabled;
	
//	if((_responseHeadersTabViewItem.enabled == NO && _responseHeadersTabViewItem.tabState == NSSelectedTab) ||
//	   (_responseBodyTabViewItem.enabled == NO && _responseBodyTabViewItem.tabState == NSSelectedTab))
//	{
//		[_tabView selectTabViewItem:_headersTabViewItem];
//	}
}

- (IBAction)sendRequest:(id)sender
{
	NSURLRequest* request = self._requestFromData;
	
	if(_dataTask != nil)
	{
		[_dataTask cancel];
	}
	
	_errorIndicator.hidden = YES;
	
	[self _setResponseTabViewItemsEnabled:NO];
	
	_progressIndicator.doubleValue += 1;
	_dataTask = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_progressIndicator.doubleValue -= 1;
			[_progressIndicator startAnimation:nil];
			[self _updateProgressIndicator];
			
			if(error != nil && error.code == NSURLErrorCancelled)
			{
				[self _setResponseTabViewItemsEnabled:NO];
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

			[_responseHeadersEditor setHeadersWithResponse:(id)response];
			[_responseEditor setBody:data response:response error:error];
			[self _setResponseTabViewItemsEnabled:YES];
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

@end
