//
//  DTXRecording+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 06/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecording+UIExtensions.h"
#import "DTXInstrumentsModel.h"
@import ObjectiveC;

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

- (NSDate *)realEndTimestamp
{
	NSDate* obj = objc_getAssociatedObject(self, _cmd);
	
	if(obj == nil)
	{
		NSFetchRequest* fr = [DTXSample fetchRequest];
		fr.fetchLimit = 1;
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
		
		obj = [[self.managedObjectContext executeFetchRequest:fr error:NULL].firstObject timestamp];
		
		objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN);
	}
	
	return obj;
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
