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

@protocol DTXSampleGroupProxy <NSObject>

@property (nonatomic, readonly) BOOL isExpandable;
@property (nonatomic, readonly) NSUInteger samplesCount;
@property (nonatomic, readonly) BOOL wantsStandardGroupDisplay;
- (id)sampleAtIndex:(NSUInteger)index;

@end

@protocol DTXSampleGroupDynamicDataLoadingProxy <DTXSampleGroupProxy>

- (BOOL)isDataLoaded;
- (void)reloadData;
- (void)prepareData;
- (void)unloadData;

@end

@interface DTXSampleContainerProxy : NSObject <DTXSampleGroupDynamicDataLoadingProxy>

@property (nonatomic, readonly, getter=isRoot) BOOL root;
@property (nonatomic, weak, readonly) NSOutlineView* outlineView;
@property (nonatomic, strong, readonly) NSFetchRequest* fetchRequest;
@property (nonatomic, strong, readonly) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, strong, readonly) NSFetchedResultsController<__kindof DTXSample*>* fetchedResultsController;

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext*)managedObjectContext isRoot:(BOOL)root;

- (void)sortWithSortDescriptors:(NSArray<NSSortDescriptor*>*)sortDescriptors;

- (void)handleSampleInserts:(NSArray*)inserts updates:(NSArray*)updates shouldReloadProxy:(BOOL*)reloadProxy;

- (id)objectForSample:(id)sample;
- (BOOL)isObjectIgnoredForUpdates:(id)object;

@end
