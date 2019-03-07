//
//  DTXRPBodyEditor.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/6/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXRPBodyEditor : NSViewController

@property (nonatomic, strong) NSData* body;

- (void)setBody:(NSData *)body response:(NSURLResponse*)response error:(NSError*)error;

@end
