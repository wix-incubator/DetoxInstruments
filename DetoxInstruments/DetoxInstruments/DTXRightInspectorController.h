//
//  DTXRightInspectorController.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 28/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DTXInspectorDataProvider.h"

@interface DTXRightInspectorController : NSViewController

@property (nonatomic, strong) DTXDocument* document;
@property (nonatomic, strong) DTXInspectorDataProvider* moreInfoDataProvider;

@end
