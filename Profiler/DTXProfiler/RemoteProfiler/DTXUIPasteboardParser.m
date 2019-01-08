//
//  DTXUIPasteboardParser.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/4/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXUIPasteboardParser.h"
#import "DTXPasteboardItem.h"
@import UIKit;
@import MobileCoreServices;

@interface DTXUIPasteboardParser () @end

@implementation DTXUIPasteboardParser

+ (NSArray<DTXPasteboardItem*>*)pasteboardItemsFromGeneralPasteboard;
{
	NSMutableArray<DTXPasteboardItem *>* supportedItems = [NSMutableArray new];
	
	NSInteger numberOfItems = UIPasteboard.generalPasteboard.numberOfItems;
	for(NSInteger pasteboardItemIdx = 0; pasteboardItemIdx < numberOfItems; pasteboardItemIdx+=1)
	{
		__block BOOL imageHandled = NO;
		__block BOOL stringHandled = NO;
		__block BOOL rtfHandled = NO;
		__block BOOL URLHandled = NO;
		__block BOOL colorHandled = NO;
		
		const NSArray<NSString*>* richTextFormats = @[
													  @"com.apple.uikit.attributedstring",
													  NS(kUTTypeRTFD),
													  NS(kUTTypeRTF),
													  ];
	
		DTXPasteboardItem* pasteboardItem = [DTXPasteboardItem new];
		
		NSArray* pasteboardTypesForItem = [UIPasteboard.generalPasteboard pasteboardTypesForItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]];
		[pasteboardTypesForItem.firstObject enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if([UIPasteboardTypeListImage containsObject:obj])
			{
				if(imageHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:NS(kUTTypeImage) data:[UIPasteboard.generalPasteboard dataForPasteboardType:NS(kUTTypeImage) inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
				
				imageHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(obj), kUTTypeRTF) == NO && ([UIPasteboardTypeListString containsObject:obj] || UTTypeConformsTo(CF(obj), kUTTypeText)))
			{
				if(stringHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:NS(kUTTypeText) data:[UIPasteboard.generalPasteboard valuesForPasteboardType:NS(kUTTypeText) inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
				stringHandled = YES;
				
				return;
			}
			
			if([UIPasteboardTypeListURL containsObject:obj])
			{
				if(URLHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:NS(kUTTypeURL) data:[UIPasteboard.generalPasteboard valuesForPasteboardType:NS(kUTTypeURL) inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
				URLHandled = YES;
				
				return;
			}
			
			if([UIPasteboardTypeListColor containsObject:obj])
			{
				if(colorHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:DTXColorPasteboardType data:[UIPasteboard.generalPasteboard valuesForPasteboardType:UIPasteboardTypeListColor.firstObject inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
				colorHandled = YES;
				
				return;
			}
			
			if([richTextFormats containsObject:obj])
			{
				if(rtfHandled == YES)
				{
					return;
				}
				
				id rtfd = [UIPasteboard.generalPasteboard valuesForPasteboardType:NS(kUTTypeRTFD) inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject;
				
				if(rtfd)
				{
					[pasteboardItem addType:NS(kUTTypeRTFD) data:rtfd];
				}
				else
				{
					//No RTFD, take the one found.
					[pasteboardItem addType:obj data:[UIPasteboard.generalPasteboard valuesForPasteboardType:obj inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
				}
				rtfHandled = YES;
				
				return;
			}
			
			[pasteboardItem addType:obj data:[UIPasteboard.generalPasteboard valuesForPasteboardType:obj inItemSet:[NSIndexSet indexSetWithIndex:pasteboardItemIdx]].firstObject];
		}];
		
		if(pasteboardItem.types.count > 0)
		{
			[supportedItems addObject:pasteboardItem];
		}
	}

	return supportedItems;
}

+ (void)setGeneralPasteboardItems:(NSArray<DTXPasteboardItem*>*)items
{
	UIPasteboard.generalPasteboard.items = @[];
	
	[items enumerateObjectsUsingBlock:^(DTXPasteboardItem * _Nonnull pasteboardItem, NSUInteger idx, BOOL * _Nonnull stop) {
		NSMutableDictionary<NSString*, id>* pbItem = [NSMutableDictionary new];
		
		[pasteboardItem.types enumerateObjectsUsingBlock:^(NSString * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
			if(UTTypeConformsTo(CF(type), kUTTypeImage))
			{
				UIImage* image = [UIImage imageWithData:[pasteboardItem dataForType:type]];
				pbItem[NS(kUTTypePNG)] = UIImagePNGRepresentation(image);
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTF))
			{
				pbItem[NS(kUTTypeRTF)] = [pasteboardItem dataForType:type];
			
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTFD))
			{
				pbItem[NS(kUTTypeRTFD)] = [pasteboardItem dataForType:type];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeURL))
			{
				pbItem[NS(kUTTypeURL)] = [pasteboardItem valueForType:type];
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeText))
			{
				pbItem[NS(kUTTypeText)] = [pasteboardItem valueForType:type];
				
				return;
			}
			
			if([type isEqualToString:DTXColorPasteboardType])
			{
				pbItem[UIPasteboardTypeAutomatic] = [pasteboardItem valueForType:type];
			}
		}];
		
		[UIPasteboard.generalPasteboard addItems:@[pbItem]];
	}];
}

@end
