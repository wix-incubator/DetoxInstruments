//
//  DTXNetworkSample+UIExtensions.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 29/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXNetworkSample+UIExtensions.h"
#import "DTXInstrumentsModelUIExtensions.h"

extern NSByteCountFormatter* __byteFormatter;

@implementation DTXNetworkSample (UIExtensions)

- (NSString *)descriptionForUI
{
	return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"URL", @""), self.url];
}

@end
