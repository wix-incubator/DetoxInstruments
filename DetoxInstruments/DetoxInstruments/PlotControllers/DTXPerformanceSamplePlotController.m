//
//  DTXPerformanceSamplePlotController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 04/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXPerformanceSamplePlotController.h"
#import "DTXScatterPlotView.h"
#import "NSAppearance+UIAdditions.h"
#import "NSColor+UIAdditions.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXSamplePlotController-Private.h"

@interface DTXPerformanceSamplePlotController () <NSFetchedResultsControllerDelegate, DTXScatterPlotViewDataSource, DTXScatterPlotViewDelegate>
{
	NSMutableArray<NSFetchedResultsController*>* _frcs;
	BOOL _frcsPrepared;
	
	NSMutableArray<NSNumber*>* _insertions;
	NSMutableArray<NSNumber*>* _updates;
	
	NSArray* _plotViews;
}

@end

@implementation DTXPerformanceSamplePlotController

- (instancetype)initWithDocument:(DTXRecordingDocument*)document isForTouchBar:(BOOL)isForTouchBar;
{
	self = [super initWithDocument:document isForTouchBar:isForTouchBar];
	
	if(self)
	{
		_frcs = [NSMutableArray new];
	}
	
	return self;
}

- (NSArray<NSString*>*)sampleKeys
{
	return @[];
}

- (BOOL)isStepped
{
	return NO;
}

- (CGFloat)plotHeightMultiplier;
{
	return self.isForTouchBar ? 1.0 : 1.15;
}

- (CGFloat)minimumValueForPlotHeight
{
	return 0.0;
}

- (void)prepareSamples
{
	if(self.document == nil || self.document.recordings.count == 0)
	{
		return;
	}
	
	if(_frcsPrepared == YES)
	{
		return;
	}
		
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sampleKey, NSUInteger idx, BOOL * _Nonnull stop) {
		NSFetchRequest* fr = [self.class.classForPerformanceSamples fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
		fr.predicate = self.predicateForPerformanceSamples;
		
		NSFetchedResultsController* frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.firstRecording.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		frc.delegate = self;
		_frcs[idx] = frc;
		
		NSError* error = nil;
		if([frc performFetch:&error] == NO)
		{
			*stop = YES;
			return;
		}
		
#if 0
		if([self.className isEqualToString:@"DTXCPUUsagePlotController"])
		{
			NSMutableDictionary* points = [NSMutableDictionary new];
			NSMutableArray* pts = [NSMutableArray new];
			
			[frc.fetchedObjects enumerateObjectsUsingBlock:^(DTXPerformanceSample* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				NSDictionary* point = @{@"position": @([[obj valueForKeyPath:@"timestamp.timeIntervalSinceReferenceDate"] doubleValue] - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate), @"value": [obj valueForKey:@"cpuUsage"]};
				[pts addObject:point];
			}];
			
			points[@"points"] = pts;
			points[@"length"] = @(self.document.lastRecording.endTimestamp.timeIntervalSinceReferenceDate - self.document.firstRecording.startTimestamp.timeIntervalSinceReferenceDate);
			
			[points writeToFile:@"/Users/lnatan/Desktop/points.plist" atomically:YES];
		}
#endif
	}];
	
	_frcsPrepared = _frcs.count == self.sampleKeys.count;
}

- (NSArray*)samplesForPlotIndex:(NSUInteger)index
{
	if(_frcs.count != self.sampleKeys.count)
	{
		[self prepareSamples];
	}
	
	return _frcs[index].fetchedObjects;
}

- (NSPredicate*)predicateForPerformanceSamples
{
	return nil;
}

+ (Class)classForPerformanceSamples
{
	return [DTXPerformanceSample class];
}

- (void)updateLayerHandler
{
	NSArray<NSColor*>* plotColors = self.plotColors;
	
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXScatterPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		BOOL isDark = self.wrapperView.effectiveAppearance.isDarkAppearance;
		BOOL isTouchBar = self.wrapperView.effectiveAppearance.isTouchBarAppearance;
		
		NSColor* lineColor;
		
		if([obj isKindOfClass:DTXScatterPlotView.class])
		{
			if(isDark || isTouchBar)
			{
				lineColor = NSColor.whiteColor;//[plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:1.0];
			}
			else
			{
				lineColor = [plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
			}
			
			obj.lineColor = lineColor;
			CGFloat maxWidth = isDark ? 1.5 : 1.0;
			obj.lineWidth = isTouchBar ? 0.0 : MAX(1.0, maxWidth / self.wrapperView.layer.contentsScale);
			
			NSColor* startColor;
			NSColor* endColor;
			
			if(isTouchBar)
			{
				startColor = self.plotColors[idx];
				//			startColor = [startColor colorWithAlphaComponent:0.4];
				endColor = startColor;
			}
			else if(isDark)
			{
				endColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.1];//[plotColors[idx] colorWithAlphaComponent:0.5];
				startColor = [self.plotColors[idx] deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25];//[plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];//[plotColors[idx] colorWithAlphaComponent:0.85];
				startColor = [startColor colorWithAlphaComponent:0.9];
				endColor = startColor;
			}
			else
			{
				startColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.5];
				endColor = [plotColors[idx] shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.7];
			}
			
			obj.fillColor1 = startColor;
			obj.fillColor2 = endColor;
		}
		else
		{
			[obj reloadData];
		}
	}];
	
	[super updateLayerHandler];
}

- (void)noteOfSampleInsertions:(NSArray<NSNumber*>*)insertions updates:(NSArray<NSNumber*>*)updates forPlotAtIndex:(NSUInteger)index
{
	DTXScatterPlotView* plotView = self.plotViews[index];
	
	for (NSNumber* obj in updates) {
		[plotView reloadPointAtIndex:obj.unsignedIntegerValue];
	}
	
	[plotView addNumberOfPoints:insertions.count];
}

#pragma mark Internal Plots

- (NSArray<__kindof DTXPlotView*>*)plotViews
{
	if(_plotViews)
	{
		return _plotViews;
	}
	
	NSMutableArray* rv = [NSMutableArray new];
	[self.sampleKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		DTXScatterPlotView* scatterPlotView = [[DTXScatterPlotView alloc] initWithFrame:CGRectZero];
		scatterPlotView.plotIndex = idx;
		scatterPlotView.delegate = self;
		
		scatterPlotView.minimumValueForPlotHeight = self.minimumValueForPlotHeight;
		scatterPlotView.stepped = self.isStepped;
		scatterPlotView.dataSource = self;
		
		if(self.sampleKeys.count == 2 && idx == 1)
		{
			scatterPlotView.flipped = YES;
		}
		
		scatterPlotView.plotHeightMultiplier = self.plotHeightMultiplier;
		
		[rv addObject:scatterPlotView];
	}];
	_plotViews = rv;
	
	return _plotViews;
}

#pragma mark DTXScatterPlotViewDelegate

- (void)plotView:(DTXScatterPlotView*)plotView didClickPointAtIndex:(NSUInteger)idx clickPositionInPlot:(double)position valueAtClickPosition:(double)value
{
	DTXSamplePlotController* someoneThatCan = self;
	
	while(someoneThatCan != nil && someoneThatCan.canReceiveFocus == NO)
	{
		someoneThatCan = (id)someoneThatCan.parentPlotController;
	}
	
	if(someoneThatCan != nil)
	{
		[self.delegate plotControllerUserDidClickInPlotBounds:someoneThatCan];
	}
	
	if(idx == NSNotFound)
	{
		[someoneThatCan removeHighlight];
		[someoneThatCan.sampleClickDelegate plotController:someoneThatCan didClickOnSample:nil];
	}
	else
	{
		DTXSample* sample = _frcs[plotView.plotIndex].fetchedObjects[idx];
		[someoneThatCan _highlightSample:sample sampleIndex:idx plotIndex:someoneThatCan == self ? plotView.plotIndex : NSNotFound positionInPlot:position valueAtClickPosition:value];
		[someoneThatCan.sampleClickDelegate plotController:someoneThatCan didClickOnSample:sample];
	}
}

#pragma mark DTXScatterPlotViewDataSource

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView *)plotView
{
	return [self samplesForPlotIndex:plotView.plotIndex].count;
}

- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView pointAtIndex:(NSUInteger)idx
{
	NSUInteger plotIdx = plotView.plotIndex;
	
	DTXScatterPlotViewPoint* rv = [DTXScatterPlotViewPoint new];
	rv.x = [[[self samplesForPlotIndex:plotIdx][idx] valueForKey:@"timestamp"] timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.y = [[self transformedValueForFormatter:[[self samplesForPlotIndex:plotIdx][idx] valueForKey:self.sampleKeys[plotIdx]]] doubleValue];
	
	return rv;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	_insertions = [NSMutableArray new];
	_updates = [NSMutableArray new];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
	if(type == NSFetchedResultsChangeInsert)
	{
		[_insertions addObject:@(newIndexPath.item)];
	}
	else if(type == NSFetchedResultsChangeUpdate)
	{
		[_updates addObject:@(indexPath.item)];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	NSUInteger index = [_frcs indexOfObject:controller];
	[self noteOfSampleInsertions:_insertions updates:_updates forPlotAtIndex:index];
	_insertions = nil;
	_updates = nil;
}

@end
