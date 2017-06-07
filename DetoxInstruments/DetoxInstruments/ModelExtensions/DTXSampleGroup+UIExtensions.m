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

@end
