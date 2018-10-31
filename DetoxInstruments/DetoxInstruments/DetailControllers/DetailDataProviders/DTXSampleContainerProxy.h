//
//  DTXSampleContainerProxy.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/1/18.
//  Copyright © 2018 Wix. All rights reserved.
//

@import Foundation;
@import AppKit;
@import CoreData;

@interface DTXSampleContainerProxy : NSObject

@property (nonatomic, readonly) NSUInteger samplesCount;
- (id)sampleAtIndex:(NSUInteger)index;

@property (nonatomic, readonly, getter=isRoot) BOOL root;
@property (nonatomic, weak, readonly) NSOutlineView* outlineView;
@property (nonatomic, strong, readonly) NSFetchRequest* fetchRequest;
@property (nonatomic, strong, readonly) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic, strong) NSDate* closeTimestamp;
@property (nonatomic, strong) NSString* name;

@property (nonatomic, strong, readonly) NSFetchedResultsController* fetchedResultsController;

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView isRoot:(BOOL)root managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
- (BOOL)isDataLoaded;
- (void)reloadData;
- (void)unloadData;

- (void)handleSampleInserts:(NSArray*)inserts updates:(NSArray*)updates shouldReloadProxy:(BOOL*)reloadProxy;

- (id)objectForSample:(id)sample;
- (BOOL)isObjectIgnoredForUpdates:(id)object;

- (BOOL)wantsStandardGroupDisplay;

@end
