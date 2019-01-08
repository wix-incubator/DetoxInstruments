//
//  DTXDocument.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/26/18.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXDocument : NSDocument

- (id)objectForPreferenceKey:(NSString*)key;
- (void)setObject:(id)object forPreferenceKey:(NSString*)key;

@end
