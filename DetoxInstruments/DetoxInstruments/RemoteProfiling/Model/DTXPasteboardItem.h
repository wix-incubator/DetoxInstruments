//
//  DTXPasteboardItem.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 5/11/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

#if ! TARGET_OS_MACCATALYST && __has_include(<Appkit/Appkit.h>)
#import <Appkit/Appkit.h>
extern NSPasteboardType const DTXColorPasteboardType;
#else
extern NSString* const DTXColorPasteboardType;
#endif


@interface DTXPasteboardItem : NSObject <NSSecureCoding>

@property (nonatomic, copy, readonly) NSOrderedSet<NSString*>* types;

- (void)addType:(NSString*)type value:(id)value;
- (void)addType:(NSString*)type data:(NSData*)data;

- (id)valueForType:(NSString*)type;
- (NSData*)dataForType:(NSString*)type;

@end
