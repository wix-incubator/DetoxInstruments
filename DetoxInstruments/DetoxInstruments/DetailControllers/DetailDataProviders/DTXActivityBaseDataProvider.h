//
//  DTXActivityBaseDataProvider.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/25/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXDetailDataProvider.h"

@interface DTXActivityBaseDataProvider : DTXDetailDataProvider

@property (nonatomic, copy) NSSet<NSString*>* enabledCategories;

@end
