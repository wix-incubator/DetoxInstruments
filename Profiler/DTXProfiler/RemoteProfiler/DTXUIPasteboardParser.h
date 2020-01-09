//
//  DTXUIPasteboardParser.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/4/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTXPasteboardItem.h"

@interface DTXUIPasteboardParser : NSObject

+ (NSArray<DTXPasteboardItem*>*)pasteboardItemsFromGeneralPasteboard;
+ (void)setGeneralPasteboardItems:(NSArray<DTXPasteboardItem*>*)items;

@end
