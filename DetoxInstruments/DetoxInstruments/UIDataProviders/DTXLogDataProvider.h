//
//  DTXLogDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXUIDataProvider.h"

@interface DTXLogDataProvider : NSObject

- (instancetype)initWithDocument:(DTXDocument*)document managedTableView:(NSTableView*)tableView;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXDocument* document;
@property (nonatomic, weak, readonly) NSTableView* managedTableView;

- (void)scrollToTimestamp:(NSDate*)timestamp;

@end
