//
//  _DTXActionButtonProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/8/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol _DTXActionButtonProvider <NSObject>

@property (nonatomic, copy, readonly) NSArray<NSButton*>* actionButtons;

@optional
@property (nonatomic, copy, readonly) NSArray<NSButton*>* moreButtons;

@end
