//
//  DTXNSPasteboardParser.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/12/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXNSPasteboardParser.h"

@import AppKit;

@implementation DTXNSPasteboardParser

+ (id)_instanceOfClass:(Class)cls fromPasteboardItem:(NSPasteboardItem*)item type:(NSString*)type pasteboard:(NSPasteboard*)pasteboard
{
	if(cls == NSData.class)
	{
		return [item dataForType:type];
	}
	
	NSPasteboardReadingOptions readingOptions = NSPasteboardReadingAsData;
	if([cls respondsToSelector:@selector(readingOptionsForType:pasteboard:)])
	{
		readingOptions = [cls readingOptionsForType:type pasteboard:pasteboard];
	}
	
	if(readingOptions == NSPasteboardReadingAsKeyedArchive)
	{
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:[item dataForType:type] error:NULL];
		unarchiver.requiresSecureCoding = NO;
		return [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	}
	
	id postprocessed;
	
	switch(readingOptions)
	{
		case NSPasteboardReadingAsPropertyList:
			postprocessed = [item propertyListForType:type];
			break;
		case NSPasteboardReadingAsString:
			postprocessed = [item stringForType:type];
			break;
		case NSPasteboardReadingAsData:
		default:
			postprocessed = [item dataForType:type];
			break;
	}
	
	return [[cls alloc] initWithPasteboardPropertyList:postprocessed ofType:type];
}

+ (NSArray<DTXPasteboardItem*>*)pasteboardItemsFromGeneralPasteboard
{
	NSMutableArray<DTXPasteboardItem *>* items = [NSMutableArray new];
	
	[NSPasteboard.generalPasteboard.pasteboardItems enumerateObjectsUsingBlock:^(NSPasteboardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		__block BOOL imageHandled = NO;
		__block BOOL stringHandled = NO;
		__block BOOL rtfHandled = NO;
		__block BOOL URLHandled = NO;
		__block BOOL colorHandled = NO;
		
		DTXPasteboardItem* pasteboardItem = [DTXPasteboardItem new];

		[obj.types enumerateObjectsUsingBlock:^(NSPasteboardType  _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
			if(UTTypeConformsTo(CF(type), kUTTypeImage))
			{
				if(imageHandled == YES)
				{
					return;
				}
				
				NSImage* image = [self _instanceOfClass:NSImage.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:NULL context:nil hints:nil]];
				
				[pasteboardItem addType:NS(kUTTypeImage) data:[newRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}]];
				
				imageHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTF))
			{
				if(rtfHandled == YES)
				{
					return;
				}
				
				NSData* data = [self _instanceOfClass:NSData.class fromPasteboardItem:obj type:NS(kUTTypeRTF) pasteboard:NSPasteboard.generalPasteboard];
				NSAttributedString* attr = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
				
				[pasteboardItem addType:NS(kUTTypeRTF) value:data];
				if(attr != nil && !stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:attr.string];
					stringHandled = YES;
				}
				rtfHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTFD))
			{
				if(rtfHandled == YES)
				{
					return;
				}
				
				NSData* data = [self _instanceOfClass:NSData.class fromPasteboardItem:obj type:NS(kUTTypeRTFD) pasteboard:NSPasteboard.generalPasteboard];
				NSAttributedString* attr = [[NSAttributedString alloc] initWithRTFD:data documentAttributes:nil];
				
				[pasteboardItem addType:NS(kUTTypeRTFD) value:data];
				if(attr != nil && !stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:attr.string];
					stringHandled = YES;
				}
				rtfHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), CF(NSPasteboardTypeString)))
			{
				if(stringHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:NS(kUTTypeText) value:[self _instanceOfClass:NSString.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard]];
				stringHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeURL))
			{
				if(URLHandled == YES)
				{
					return;
				}
				
				NSURL* URL = [self _instanceOfClass:NSURL.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				[pasteboardItem addType:NS(kUTTypeURL) value:URL];
				if(!stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:URL.absoluteString];
					stringHandled = YES;
				}
				URLHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), CF(NSPasteboardTypeColor)))
			{
				if(colorHandled == YES)
				{
					return;
				}
				
				NSColor* color = [self _instanceOfClass:NSColor.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				
				//Translate color from system color to normal color.
				color = [color colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
				[pasteboardItem addType:DTXColorPasteboardType value:color];
				colorHandled = YES;
				
				return;
			}
		}];
		
		[items addObject:pasteboardItem];
	}];
	
	return items;
}

+ (void)setGeneralPasteboardItems:(NSArray<DTXPasteboardItem*>*)pasteboardItems
{
	[NSPasteboard.generalPasteboard clearContents];
	NSMutableArray<NSPasteboardItem*>* pbItems = [NSMutableArray new];
	
	[pasteboardItems enumerateObjectsUsingBlock:^(DTXPasteboardItem * _Nonnull pasteboardItem, NSUInteger idx, BOOL * _Nonnull stop) {
		NSPasteboardItem* pbItem = [NSPasteboardItem new];
		
		[pasteboardItem.types enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
			if(UTTypeConformsTo(CF(type), kUTTypeImage))
			{
				NSImage* image = [[NSImage alloc] initWithData:[pasteboardItem dataForType:type]];
				[pbItem setData:image.TIFFRepresentation forType:NSPasteboardTypeTIFF];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTF))
			{
				[pbItem setPropertyList:[pasteboardItem dataForType:type] forType:NSPasteboardTypeRTF];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTFD))
			{
				[pbItem setPropertyList:[pasteboardItem dataForType:type] forType:NSPasteboardTypeRTFD];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeURL))
			{
				[pbItem setString:[[pasteboardItem valueForType:type] absoluteString] forType:NSPasteboardTypeURL];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeText))
			{
				[pbItem setString:[pasteboardItem valueForType:type] forType:NSPasteboardTypeString];
				
				return;
			}
			
			if([type isEqualToString:DTXColorPasteboardType])
			{
				[pbItem setPropertyList:[[pasteboardItem valueForType:type] pasteboardPropertyListForType:NSPasteboardTypeColor] forType:NSPasteboardTypeColor];
				
				return;
			}
		}];
		
		[pbItems addObject:pbItem];
	}];
	
	[NSPasteboard.generalPasteboard writeObjects:pbItems];
}

@end
