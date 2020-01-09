//
//  DTXPieChartView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/06/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTXPieChartEntry : NSObject

@property (nonatomic, strong, readonly) NSNumber* value;
@property (nonatomic, copy, readonly) NSString* title;
@property (nonatomic, strong, readonly) NSColor* color;

+ (instancetype)entryWithValue:(NSNumber*)value title:(NSString*)title color:(NSColor*)color;

@end

@interface DTXPieChartView : NSView

@property (nonatomic, copy, readonly) NSArray<DTXPieChartEntry*>* entries;
@property (nonatomic, assign, readonly) NSUInteger highlightedEntry;

- (void)setEntries:(NSArray<DTXPieChartEntry *> *)entries highlightedEntry:(NSUInteger)highlightedEntry;

@end
