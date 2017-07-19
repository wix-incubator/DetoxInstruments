//
//  NSManagedObject+Additions.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Additions)

@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationForJSON;
@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationForPropertyList;
@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationOfChangedValuesForPropertyList;

@end
