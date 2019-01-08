//
//  DTXSampleGroupProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#if 0

#import "DTXSampleGroupProxy.h"
#import "DTXSampleGroup+UIExtensions.h"

@interface DTXSampleGroupProxy ()
{
	NSMapTable<DTXSampleGroup*, DTXSampleGroupProxy*>* _groupToProxyMapping;
}

@property (nonatomic, strong, readwrite) NSString* name;
@property (nonatomic, strong, readwrite) NSDate* timestamp;
@property (nonatomic, strong, readwrite) NSDate* closeTimestamp;

@end

@implementation DTXSampleGroupProxy

- (id)objectForSample:(id)sample
{
	if([sample isKindOfClass:[DTXSampleGroup class]])
	{
		DTXSampleGroup* sampleGroup = (id)sample;
		
		DTXSampleGroupProxy* groupProxy = [_groupToProxyMapping objectForKey:sampleGroup];
		
		if(groupProxy == nil)
		{
			groupProxy = [[DTXSampleGroupProxy alloc] initWithOutlineView:self.outlineView managedObjectContext:self.managedObjectContext isRoot:NO sampleTypes:self.sampleTypes];
			groupProxy.name = sampleGroup.name;
			groupProxy.timestamp = sampleGroup.timestamp;
			groupProxy.closeTimestamp = sampleGroup.closeTimestamp;
			[_groupToProxyMapping setObject:groupProxy forKey:sampleGroup];
		}
		
		return groupProxy;
	}
	else
	{
		return sample;
	}
}

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext sampleTypes:(NSArray<NSNumber*>*)sampleTypes;
{
	return [self initWithOutlineView:outlineView managedObjectContext:managedObjectContext isRoot:YES sampleTypes:sampleTypes];
}

- (instancetype)initWithOutlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext isRoot:(BOOL)isRoot sampleTypes:(NSArray<NSNumber*>*)sampleTypes
{
	self = [super initWithOutlineView:outlineView managedObjectContext:managedObjectContext isRoot:isRoot];
	if(self)
	{
		_sampleTypes = sampleTypes;
		_groupToProxyMapping = [NSMapTable strongToStrongObjectsMapTable];
	}
	return self;
}

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [NSFetchRequest new];
	fr.entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext:self.managedObjectContext];
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO && sampleType in %@", [_sampleTypes arrayByAddingObjectsFromArray:@[@(DTXSampleTypeTag)]]];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

- (BOOL)isObjectIgnoredForUpdates:(id)object
{
	return [object isKindOfClass:[DTXSampleGroup class]];
}

- (BOOL)wantsStandardGroupDisplay
{
	return YES;
}

@end

#endif
