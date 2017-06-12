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

- (NSArray<DTXSample *>*)samplesWithTypes:(NSArray<NSNumber*>*)sampleTypes includingGroups:(BOOL)includeGroups
{
	NSFetchRequest* fr = [DTXSample fetchRequest];
	fr.includesSubentities = YES;
	fr.predicate = [NSPredicate predicateWithFormat:@"sampleType in %@ && parentGroup == %@", [sampleTypes arrayByAddingObjectsFromArray:@[@(DTXSampleTypeGroup), @(DTXSampleTypeTag)]], self];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	return [self.managedObjectContext executeFetchRequest:fr error:NULL];
}

@end
