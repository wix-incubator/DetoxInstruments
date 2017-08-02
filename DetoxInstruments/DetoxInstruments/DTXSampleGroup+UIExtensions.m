//
//  DTXSampleGroup+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXSampleGroup+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"

@implementation DTXSampleGroup (UIExtensions)

- (NSString *)descriptionForUI
{
	return self.name ?: [NSDateFormatter localizedStringFromDate:self.timestamp dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
}

- (NSFetchRequest<DTXSample*>*)fetchRequestForSamplesWithTypes:(NSArray<NSNumber*>*)sampleTypes includingGroups:(BOOL)includeGroups
{
	NSFetchRequest* fr = [NSFetchRequest new];
	fr.entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext:self.managedObjectContext];
	fr.includesSubentities = YES;
	fr.predicate = [NSPredicate predicateWithFormat:@"sampleType in %@ && parentGroup == %@", [sampleTypes arrayByAddingObjectsFromArray:@[@(DTXSampleTypeGroup), @(DTXSampleTypeTag)]], self];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return fr;
}

@end
