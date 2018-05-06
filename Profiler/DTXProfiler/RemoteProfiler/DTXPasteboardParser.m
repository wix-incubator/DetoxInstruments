//
//  DTXPasteboardParser.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/4/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXPasteboardParser.h"
@import UIKit;

//@interface UIImage (DTXEncodedData) @end
//
//@implementation UIImage (DTXEncodedData)
//
//- (NSData*)encodedData
//{
//	return UIImagePNGRepresentation(self);
//}
//
//@end

@interface DTXPasteboardParser () <NSKeyedArchiverDelegate> @end

@implementation DTXPasteboardParser

+ (NSData*)dataFromGeneralPasteboard;
{
	DTXPasteboardParser* delegate = [DTXPasteboardParser new];
	NSKeyedArchiver* archiver = [NSKeyedArchiver new];
	archiver.delegate = delegate;
	
	[archiver encodeObject:UIPasteboard.generalPasteboard.items forKey:NSKeyedArchiveRootObjectKey];
	
	NSLog(@"%@", UIPasteboard.generalPasteboard.items);
	
	[archiver finishEncoding];
	
	return archiver.encodedData;
}

- (nullable id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object
{
	return object;
}

@end
