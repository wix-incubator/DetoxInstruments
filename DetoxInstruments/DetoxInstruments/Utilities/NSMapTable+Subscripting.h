//
//  NSMapTable+Subscripting.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/27/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMapTable (Subscripting)

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;

@end
