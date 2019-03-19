//
//  DTXRPBodyEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/6/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRPBodyEditor.h"

@interface DTXRPBodyEditor () <NSUserInterfaceValidations>

@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong, readwrite) NSData* body;

@end

@implementation DTXRPBodyEditor
{
	BOOL _loading;
	
	IBOutlet NSScrollView* _textScrollView;
	IBOutlet NSTextView* _textView;
	IBOutlet NSTextField* _contentTypeTextField;
	IBOutlet NSStackView* _bodyTypeButtonsStackView;
	IBOutlet NSImageView* _fileImageView;
	IBOutlet NSStackView* _fileBrowseButtons;
	IBOutlet NSButton* _fileSaveButton;
	IBOutlet NSButton* _clearButton;
	IBOutlet NSTextField* _noBodyLabel;
	IBOutlet NSButton* _textBodyTypeButton;
}

- (void)setBody:(NSData *)body
{
	[self willChangeValueForKey:@"text"];
	[self willChangeValueForKey:@"body"];
	_body = body;
	[self didChangeValueForKey:@"body"];
	[self didChangeValueForKey:@"text"];
	
	if(_loading == NO)
	{
		[self.view.window.windowController.document updateChangeCount:NSChangeDone];
	}
	
	_fileSaveButton.enabled = _body.length > 0;
	_clearButton.enabled = _body.length > 0;
}

- (void)setContentType:(NSString *)contentType
{
	if([contentType isEqualToString:_contentType] == NO)
	{
		_contentType = contentType;
		
		if(_loading == NO)
		{
			[self.view.window.windowController.document updateChangeCount:NSChangeDone];
		}
		
		if(self.body.length > 0)
		{
			NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(contentType), NULL));
			NSImage* image = [[NSWorkspace sharedWorkspace] iconForFileType:UTI];
			image.size = NSMakeSize(256, 256);
			_fileImageView.image = image;
		}
		else
		{
			_fileImageView.image = nil;
		}
		
//		_textBodyTypeButton.enabled = self._isContentTypeBinary == NO;
	}
}

- (NSDictionary*)_propertyListFromURLEncodedFormData:(NSData*)data encodingCharset:(NSString*)charset didContainIllegalCharacter:(out BOOL*)didContain
{
	*didContain = NO;
	
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	NSString* formString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray* keyValues = [formString componentsSeparatedByString:@"&"];
	
	if(keyValues.count == 0)
	{
		return rv;
	}
	
	[keyValues enumerateObjectsUsingBlock:^(NSString* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if(obj.length == 0)
		{
			return;
		}
		
		NSArray* keyAndOrValue = [obj componentsSeparatedByString:@"="];
		NSString* key = keyAndOrValue.firstObject;
		
		if([key rangeOfCharacterFromSet:NSCharacterSet.URLQueryAllowedCharacterSet.invertedSet].location != NSNotFound)
		{
			*didContain |= YES;
		}
		
		key = [key stringByRemovingPercentEncoding];
		NSString* value = @"";
		
		if(keyAndOrValue.count > 1)
		{
			value = keyAndOrValue.lastObject;
			
			if([value rangeOfCharacterFromSet:NSCharacterSet.URLQueryAllowedCharacterSet.invertedSet].location != NSNotFound)
			{
				*didContain |= YES;
			}
			
			value = [value stringByRemovingPercentEncoding];
		}
		
		rv[key] = value;
	}];
	
	return rv;
}

-(NSData*)_urlEncodedBodyFromPropertyList
{
	NSMutableString* rv = [NSMutableString new];
	[(NSDictionary*)self.plistEditor.propertyList enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		key = [key stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
		obj = [obj stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
		[rv appendFormat:@"%@=%@&", key, obj];
	}];
	
	return [rv dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)setText:(NSString *)text
{
	self.body = [text dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)text
{
	if([(NSButton*)[_bodyTypeButtonsStackView viewWithTag:1] state] != NSControlStateValueOn)
	{
		return @"";
	}
	
	return [[NSString alloc] initWithData:self.body encoding:NSUTF8StringEncoding];
}

- (IBAction)setBodyType:(NSButton*)sender
{
	switch (sender.tag)
	{
		case 0: //None
			self.body = nil;
			self.contentType = @"";
			break;
		case 1: //Raw Text
			break;
		case 2: //URL Encoded Form
			self.contentType = @"application/x-www-form-urlencoded";
			break;
		case 3: //File
			break;
		case 4: //Multipart Form
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@""];
			break;
	}
	
	[self _updateToState];
}

- (void)_reloadURLEncodedForm
{
	BOOL containIllegalCharacter = NO;
	id obj = [self _propertyListFromURLEncodedFormData:_body encodingCharset:nil didContainIllegalCharacter:&containIllegalCharacter];
	if(obj != nil)
	{
		self.plistEditor.propertyList = obj;
	}
	else
	{
		//TODO: Handle parse error
	}
}

- (BOOL)_isContentTypeBinary
{
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(self.contentType), NULL);
	dtx_defer {
		if(UTI != NULL)
		{
			CFRelease(UTI);
		}
	};
	
	return UTTypeConformsTo(UTI, kUTTypeText) == NO;
}

- (void)setBody:(NSData *)body withContentType:(NSString*)contentType
{
	_loading = YES;
	
	self.body = body;
	self.contentType = contentType ?: @"";
	
	if(self.body.length == 0 && self.contentType.length == 0)
	{
		[(NSButton*)[_bodyTypeButtonsStackView viewWithTag:0] setState:NSControlStateValueOn];
	}
	else if([self.contentType hasPrefix:@"application/x-www-form-urlencoded"])
	{
		[(NSButton*)[_bodyTypeButtonsStackView viewWithTag:2] setState:NSControlStateValueOn];
		[self _reloadURLEncodedForm];
	}
	else if(self._isContentTypeBinary)
	{
		[(NSButton*)[_bodyTypeButtonsStackView viewWithTag:3] setState:NSControlStateValueOn];
	}
	else
	{
		[(NSButton*)[_bodyTypeButtonsStackView viewWithTag:1] setState:NSControlStateValueOn];
	}
	
	[self _updateToState];
	
	_loading = NO;
}

- (void)_updateToState
{
	BOOL isNoBody = [(NSButton*)[_bodyTypeButtonsStackView viewWithTag:0] state] == NSControlStateValueOn;
	BOOL isRawText = [(NSButton*)[_bodyTypeButtonsStackView viewWithTag:1] state] == NSControlStateValueOn;
	BOOL isFile = [(NSButton*)[_bodyTypeButtonsStackView viewWithTag:3] state] == NSControlStateValueOn;
	BOOL isURLEncoded = [(NSButton*)[_bodyTypeButtonsStackView viewWithTag:2] state] == NSControlStateValueOn;
	
	_contentTypeTextField.enabled = isRawText || isFile;
	_textScrollView.hidden = isRawText == NO;
	self.plistEditor.hidden = isURLEncoded == NO;
	_fileImageView.hidden = isFile == NO;
	_fileBrowseButtons.hidden = isFile == NO;
	_noBodyLabel.hidden = isNoBody == NO;
	
	if(isRawText)
	{
		[self willChangeValueForKey:@"text"];
		[self didChangeValueForKey:@"text"];
	}
	else if(isURLEncoded)
	{
		[self _reloadURLEncodedForm];
	}
}

- (IBAction)clearFile:(id)sender
{
	self.body = nil;
	self.contentType = @"";
}

- (IBAction)selectFile:(id)sender
{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = NO;
	openPanel.canChooseFiles = YES;
	openPanel.message = NSLocalizedString(@"Select file to use as body content.", @"");
	
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
		if(returnCode != NSModalResponseOK)
		{
			return;
		}
		
		self.body = [[NSData alloc] initWithContentsOfURL:openPanel.URL options:(NSDataReadingMappedIfSafe) error:NULL];
		NSString* type;
		[openPanel.URL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
		NSString* MIMEType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(CF(type), kUTTagClassMIMEType));
		self.contentType = MIMEType ?: @"application/octet-stream";
	}];
}

- (IBAction)saveFile:(id)sender
{
	NSSavePanel* savePanel = [NSSavePanel savePanel];
	
	NSString* UTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, CF(self.contentType), NULL));
	NSString* extension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(CF(UTI), kUTTagClassFilenameExtension));
	if(extension == nil)
	{
		extension = @"bin";
	}
	
	NSString* fileName = [NSString stringWithFormat:@"Body.%@", extension];
	
	savePanel.nameFieldStringValue = fileName;
	
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
		if(returnCode != NSModalResponseOK)
		{
			return;
		}
		
		[self.body writeToURL:savePanel.URL atomically:YES];
	}];
}

#pragma mark NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	if(item.tag == 2 && self.contentType.length > 0 && [self.contentType hasPrefix:@"application/x-www-form-urlencoded"] == NO)
	{
		NSAlert* alert = [NSAlert new];
		alert.alertStyle = NSAlertStyleWarning;
		alert.messageText = NSLocalizedString(@"Incompatible body content type", @"");
		alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"The body currently has a content type of “%@” which may not be compatible with “application/x-www-form-urlencoded”.\n\nYou can try parsing the existing body with the new content type or clear the body and start fresh.", @""), self.contentType];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Try Parsing", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Clear Body", @"")];
//		#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//		NSRunAlertPanel(@"A", @"B", @"Cancel", @"Try Parsing", @"Clear");
		
		NSUInteger result = [alert runModal];
		if(result == NSAlertFirstButtonReturn)
		{
			return NO;
		}
		else if(result == NSAlertThirdButtonReturn)
		{
			self.body = nil;
		}
	}
	
	return YES;
}

#pragma mark LNPropertyListEditorDelegate

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	self.body = self._urlEncodedBodyFromPropertyList;
}

@end
