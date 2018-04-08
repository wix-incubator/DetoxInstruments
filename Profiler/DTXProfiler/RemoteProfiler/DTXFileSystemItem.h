//
//  DTXFileSystemItem.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 3/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTXFileSystemItem : NSObject <NSSecureCoding>

@property (nonatomic) BOOL isDirectory;
@property (nonatomic) BOOL isDirectoryForUI;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSNumber* size;
@property (nonatomic, copy) NSArray* children;
@property (nonatomic, copy) NSURL* URL;

- (instancetype)initWithFileURL:(NSURL*)fileURL;

- (NSData*)contents;
- (NSData*)zipContents;

@end
