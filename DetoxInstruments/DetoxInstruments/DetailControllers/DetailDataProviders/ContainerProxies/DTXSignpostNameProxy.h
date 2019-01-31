//
//  DTXSignpostNameProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/2/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXSampleContainerProxy.h"
#import "DTXRecording+Additions.h"
#import "DTXSignpostProtocol.h"

@interface DTXSignpostNameProxy : DTXSampleContainerProxy <DTXSignpost>

@property (nonatomic, strong, readonly) NSString* category;

- (instancetype)initWithCategory:(NSString*)category name:(NSString*)name info:(NSDictionary*)info managedObjectContext:(NSManagedObjectContext*)managedObjectContext outlineView:(NSOutlineView*)outlineView;

@end
