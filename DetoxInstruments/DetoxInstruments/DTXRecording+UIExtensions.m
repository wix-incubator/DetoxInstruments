//
//  DTXRecording+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+UIExtensions.h"
#import "DTXInstrumentsModel.h"
#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"
@import ObjectiveC;

NSString* const DTXRecordingDidInvalidateDefactoEndTimestamp = @"DTXRecordingDidInvalidateDefactoEndTimestamp";

@implementation DTXRecording (UIExtensions)

- (DTXProfilingConfiguration *)dtx_profilingConfiguration
{
	if(self.profilingConfiguration == nil)
	{
		return nil;
	}
	
	DTXProfilingConfiguration* obj = objc_getAssociatedObject(self, _cmd);
	
		if(obj == nil)
		{
			obj = [[DTXProfilingConfiguration alloc] initWithCoder:(id)self.profilingConfiguration];
			objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
		}
				   
	return obj;
}

- (NSDate *)defactoStartTimestamp
{
	NSDate* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSFetchRequest* fr = [DTXPerformanceSample fetchRequest];
		fr.fetchLimit = 1;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		obj = [[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject timestamp];
		if(obj == nil)
		{
			obj = self.startTimestamp;
		}
		
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
}

- (NSDate *)defactoEndTimestamp
{
	NSDate* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSFetchRequest* fr = [DTXPerformanceSample fetchRequest];
		fr.fetchLimit = 1;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
		
		obj = [[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject timestamp];
		
		NSDate* startWithMinimum = [self.startTimestamp dateByAddingTimeInterval:self.minimumDefactoTimeInterval];
		if(obj == nil || [obj compare:startWithMinimum] == NSOrderedAscending)
		{
			obj = startWithMinimum;
		}
		
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
}

- (void)invalidateDefactoEndTimestamp
{
	objc_setAssociatedObject(self, @selector(defactoEndTimestamp), nil, OBJC_ASSOCIATION_RETAIN);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXRecordingDidInvalidateDefactoEndTimestamp object:self];
}

- (NSTimeInterval)minimumDefactoTimeInterval
{
	return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setMinimumDefactoTimeInterval:(NSTimeInterval)minimumDefactoTimeInterval
{
	objc_setAssociatedObject(self, @selector(minimumDefactoTimeInterval), @(minimumDefactoTimeInterval), OBJC_ASSOCIATION_RETAIN);
	
	[self invalidateDefactoEndTimestamp];
}

- (BOOL)hasNetworkSamples
{
	NSNumber* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
		obj = @([self.managedObjectContext countForFetchRequest:fr error:NULL] > 0);
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return [obj boolValue];
}

@end
