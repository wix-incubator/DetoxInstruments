//
//  DTXBottomContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 25/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInstrumentsModel.h"
#import "DTXDetailDataProvider.h"

@class DTXBottomContentController;

@protocol DTXBottomContentControllerDelegate

- (void)bottomController:(DTXBottomContentController*)bc updateWithInspectorProvider:(DTXInspectorDataProvider*)inspectorProvider;

@end

@interface DTXBottomContentController : NSViewController

@property (nonatomic, strong) DTXDocument* document;
@property (nonatomic, weak) id<DTXBottomContentControllerDelegate> delegate;
@property (nonatomic, strong) DTXDetailDataProvider* managingDataProvider;

@end
