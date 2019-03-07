//
//  DTXRPBodyEditor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/6/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXRPBodyEditor.h"

@interface DTXRPBodyEditor ()

@property (nonatomic, strong) NSString* text;

@end

@implementation DTXRPBodyEditor
{
	IBOutlet NSTextView* _textView;
}

- (void)setBody:(NSData *)body
{
	[self willChangeValueForKey:@"body"];
	[self willChangeValueForKey:@"text"];
	_body = body;
	[self didChangeValueForKey:@"text"];
	[self didChangeValueForKey:@"body"];
}

- (void)setText:(NSString *)text
{
	self.body = [text dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)text
{
	return [[NSString alloc] initWithData:self.body encoding:NSUTF8StringEncoding];
}

- (void)setBody:(NSData *)body response:(NSURLResponse*)response error:(NSError*)error
{
	_textView.editable = NO;
	_textView.selectable = YES;
	
	if(error)
	{
		self.body = [[error localizedDescription] dataUsingEncoding:NSUTF8StringEncoding];
	}
	else
	{
		self.body = body;
	}
}

@end
