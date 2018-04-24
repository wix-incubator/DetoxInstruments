//
//  DTXThreadInfo+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/24/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXThreadInfo+UIExtensions.h"

@implementation DTXThreadInfo (UIExtensions)

- (NSString*)friendlyName
{
	if(self.number == 0)
	{
		return NSLocalizedString(@"0 (Main Thread)", @"");
	}
	
	return [NSString stringWithFormat:@"%@%@%@", self.name.length == 0 ? NSLocalizedString(@"Thread ", @"") : @"", @(self.number), self.name.length > 0 ? [NSString stringWithFormat:@" (%@)", self.name] : @""];
}

@end
