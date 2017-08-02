//
//  DTXMainContentController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 01/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXUIDataProvider.h"

@class DTXMainContentController;

@protocol DTXMainContentControllerDelegate

- (void)contentController:(DTXMainContentController*)cc updateUIWithUIProvider:(DTXUIDataProvider*)dataProvider;

@end

@interface DTXMainContentController : NSViewController

@property (nonatomic, strong) DTXDocument* document;
@property (nonatomic, weak) id<DTXMainContentControllerDelegate> delegate;

@end
