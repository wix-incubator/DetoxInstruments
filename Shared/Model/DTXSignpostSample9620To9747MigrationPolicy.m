//
//  DTXSignpostSample9620To9747MigrationPolicy.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/30/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import "DTXSignpostSample9620To9747MigrationPolicy.h"
#import "NSString+Hashing.h"

@implementation DTXSignpostSample9620To9747MigrationPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sourceInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError * _Nullable __autoreleasing *)error
{
	NSMutableArray *sourceKeys = [sourceInstance.entity.attributesByName.allKeys mutableCopy];
	NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];
	NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:mapping.destinationEntityName inManagedObjectContext:manager.destinationContext];
	NSArray *destinationKeys = destinationInstance.entity.attributesByName.allKeys;
	for (NSString *key in destinationKeys)
	{
		id value = [sourceValues valueForKey:key];
		// Avoid NULL values
		if (value && ![value isEqual:[NSNull null]])
		{
			[destinationInstance setValue:value forKey:key];
		}
	}
	 
	NSString* category = [sourceInstance valueForKey:@"category"];
	NSData* categoryHash = category.sufficientHash;
	[destinationInstance setValue:categoryHash forKey:@"categoryHash"];
	NSString* name = [sourceInstance valueForKey:@"name"];
	NSData* nameHash = name.sufficientHash;
	[destinationInstance setValue:nameHash forKey:@"nameHash"];
	
	[manager associateSourceInstance:sourceInstance withDestinationInstance:destinationInstance forEntityMapping:mapping];
	
	return YES;
}

@end
