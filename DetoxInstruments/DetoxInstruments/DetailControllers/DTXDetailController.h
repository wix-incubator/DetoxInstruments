//
//  DTXDetailController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXDetailDataProvider.h"

@class DTXDetailController;

@protocol DTXDetailControllerDelegate

- (void)detailController:(DTXDetailController*)detailController didSelectInspectorItem:(DTXInspectorDataProvider*)item;

@end

@interface DTXDetailController : NSViewController <DTXDetailDataProviderDelegate, DTXWindowWideCopyHanler>

@property (nonatomic, strong) DTXDetailDataProvider* detailDataProvider;
@property (nonatomic, weak) id<DTXDetailControllerDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL supportsDataFiltering;
- (void)updateViewWithInsets:(NSEdgeInsets)insets;
- (void)filterSamples:(NSString*)filter;
- (void)selectSample:(DTXSample*)sample;

@property (nonatomic, copy, readonly) NSString* displayName;
@property (nonatomic, strong, readonly) NSImage* smallDisplayIcon;

@property (nonatomic, strong, readonly) NSView* viewForCopy;

@end
