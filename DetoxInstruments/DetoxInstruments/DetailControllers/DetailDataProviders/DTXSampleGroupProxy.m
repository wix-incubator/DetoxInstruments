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
			groupProxy = [[DTXSampleGroupProxy alloc] initWithSampleGroup:sampleGroup sampleTypes:self.sampleTypes isRoot:NO outlineView:self.outlineView];
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

- (instancetype)initWithSampleGroup:(DTXSampleGroup*)sampleGroup sampleTypes:(NSArray<NSNumber*>*)sampleTypes outlineView:(NSOutlineView*)outlineView
{
	return [self initWithSampleGroup:sampleGroup sampleTypes:sampleTypes isRoot:YES outlineView:outlineView];
}

- (instancetype)initWithSampleGroup:(DTXSampleGroup*)sampleGroup sampleTypes:(NSArray<NSNumber*>*)sampleTypes isRoot:(BOOL)isRoot outlineView:(NSOutlineView*)outlineView;
{
	self = [super initWithOutlineView:outlineView isRoot:isRoot managedObjectContext:sampleGroup.managedObjectContext];
	if(self)
	{
		_sampleTypes = sampleTypes;
		_sampleGroup = sampleGroup;
		_groupToProxyMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	}
	return self;
}

- (NSFetchRequest *)fetchRequest
{
	NSFetchRequest* fr = [_sampleGroup fetchRequestForSamplesWithTypes:_sampleTypes includingGroups:YES];
//	NSManagedObjectContext* ctx = _sampleGroup.managedObjectContext;
	
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
