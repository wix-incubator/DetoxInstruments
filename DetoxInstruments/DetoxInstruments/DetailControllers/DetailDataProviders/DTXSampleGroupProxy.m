//
//  DTXSampleGroupProxy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 12/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSampleGroupProxy.h"
#import "DTXSampleGroup+UIExtensions.h"

@interface DTXSampleGroupProxy ()
{
	NSString* _name;
	NSMapTable<DTXSampleGroup*, DTXSampleGroupProxy*>* _groupToProxyMapping;
}

@end

@implementation DTXSampleGroupProxy

- (void)setName:(NSString *)name { _name = name; }
- (NSString *)name { return _name; }

- (id)objectForSample:(id)sample
{
	if([sample isKindOfClass:[DTXSampleGroup class]])
	{
		DTXSampleGroup* sampleGroup = (id)sample;
		
		DTXSampleGroupProxy* groupProxy = [_groupToProxyMapping objectForKey:sampleGroup];
		
		if(groupProxy == nil)
		{
			groupProxy = [[DTXSampleGroupProxy alloc] initWithSampleTypes:self.sampleTypes isRoot:NO outlineView:self.outlineView managedObjectContext:self.managedObjectContext];
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

- (instancetype)initWithSampleTypes:(NSArray<NSNumber*>*)sampleTypes outlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	return [self initWithSampleTypes:sampleTypes isRoot:YES outlineView:outlineView managedObjectContext:managedObjectContext];
}

- (instancetype)initWithSampleTypes:(NSArray<NSNumber*>*)sampleTypes isRoot:(BOOL)isRoot outlineView:(NSOutlineView*)outlineView managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	self = [super initWithOutlineView:outlineView isRoot:isRoot managedObjectContext:managedObjectContext];
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
