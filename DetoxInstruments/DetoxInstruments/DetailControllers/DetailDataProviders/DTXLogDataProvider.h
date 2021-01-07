//
//  DTXLogDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 17/06/2017.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXDetailDataProvider.h"

@interface DTXLogDataProvider : NSObject <DTXDetailDataProvider>

- (instancetype)initWithDocument:(DTXRecordingDocument*)document;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) DTXRecordingDocument* document;
@property (nonatomic, weak) id<DTXDetailDataProviderDelegate> delegate;
@property (nonatomic, weak) NSTableView* managedTableView;

- (void)scrollToTimestamp:(NSDate*)timestamp;

@end
