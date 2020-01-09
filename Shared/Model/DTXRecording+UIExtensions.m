//
//  DTXRecording+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRecording+UIExtensions.h"
#import "DTXInstrumentsModel.h"
#import "DTXProfilingConfiguration.h"
#import "AutoCoding.h"
@import ObjectiveC;

NSString* const DTXRecordingDidInvalidateDefactoEndTimestamp = @"DTXRecordingDidInvalidateDefactoEndTimestamp";

@implementation DTXRecording (UIExtensions)

- (NSDate *)defactoStartTimestamp
{
	NSDate* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSFetchRequest* fr = [DTXSample fetchRequest];
		fr.fetchLimit = 1;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		
		obj = [(DTXSample*)[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject timestamp];
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
		NSFetchRequest* fr = [DTXSample fetchRequest];
		fr.fetchLimit = 1;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
		
		obj = [(DTXSample*)[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject timestamp];
		
		if(obj == nil)
		{
			obj = self.endTimestamp;
		}
		
		if(obj == nil)
		{
			obj = self.startTimestamp;
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
