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
@import LNInterpolation;

@interface DTXPerformanceSamplePlotController () <NSFetchedResultsControllerDelegate, DTXScatterPlotViewDataSource, DTXScatterPlotViewDelegate>
{
	NSFetchedResultsController* _frc;
	BOOL _frcPrepared;
	
	NSMutableArray<NSNumber*>* _insertions;
	NSMutableArray<NSNumber*>* _updates;
	
	NSArray* _plotViews;
}

@end

@implementation DTXPerformanceSamplePlotController

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
	return 1.15;
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
	
	if(_frcPrepared == YES)
	{
		return;
	}
	
	NSFetchRequest* fr = [self.class.classForPerformanceSamples fetchRequest];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	fr.predicate = self.predicateForPerformanceSamples;
	
	NSFetchedResultsController* frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.document.viewContext sectionNameKeyPath:nil cacheName:nil];
	frc.delegate = self;
	_frc = frc;
	
	NSError* error = nil;
	if([_frc performFetch:&error] == NO)
	{
		return;
	}
	
	_frcPrepared = YES;
}

- (NSArray*)samplesForPlotIndex:(NSUInteger)index
{
	if(_frcPrepared == NO)
	{
		[self prepareSamples];
	}
	
	return _frc.fetchedObjects;
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
	[self.plotViews enumerateObjectsUsingBlock:^(__kindof DTXScatterPlotView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		BOOL isDark = self.wrapperView.effectiveAppearance.isDarkAppearance;
		BOOL isTouchBar = self.wrapperView.effectiveAppearance.isTouchBarAppearance;
		
		NSColor* plotColorForIdx = [self _plotColorForIdx:idx];
		
		NSColor* lineColor;
		
		if([obj isKindOfClass:DTXScatterPlotView.class])
		{
			if(isDark || isTouchBar)
			{
				lineColor = NSColor.whiteColor;
			}
			else
			{
				lineColor = [plotColorForIdx deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.15];
			}
			
			obj.lineColor = lineColor;
			
			CGFloat maxWidth = isDark ? 1.5 : 1.0;
			obj.lineWidth = isTouchBar ? 0.0 : MAX(1.0, maxWidth / self.wrapperView.layer.contentsScale);
			
			NSColor* startColor;
			NSColor* endColor;
			
			if(isTouchBar)
			{
				startColor = plotColorForIdx;
				//			startColor = [startColor colorWithAlphaComponent:0.4];
				endColor = startColor;
			}
			else if(isDark)
			{
				startColor = [[plotColorForIdx deeperColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.25] colorWithAlphaComponent:0.9];
				endColor = startColor;
			}
			else
			{
				startColor = [plotColorForIdx shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.5];
				endColor = [plotColorForIdx shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.7];
			}
			
			obj.fillColor1 = startColor;
			obj.fillColor2 = endColor;
			
			if([self hasAdditionalPointsForPlotView:obj])
			{
				NSColor* additionalPlotColor = [self _additionalPlotColorForIdx:idx];
				
				if(isTouchBar)
				{
					obj.additionalFillColor1 = [additionalPlotColor colorWithAlphaComponent:0.85];
					obj.additionalFillColor2 = obj.additionalFillColor1;
				}
				else if(isDark)
				{
					obj.additionalLineColor = [additionalPlotColor shallowerColorWithAppearance:self.wrapperView.effectiveAppearance modifier:0.3];
					obj.additionalFillColor2 = [startColor interpolateToValue:additionalPlotColor progress:0.25];
					obj.additionalFillColor1 = obj.additionalFillColor2;
				}
				else
				{
					obj.additionalLineColor = additionalPlotColor;
					obj.additionalFillColor2 = [startColor interpolateToValue:additionalPlotColor progress:0.15];
					obj.additionalFillColor1 = obj.additionalFillColor2;
				}
			}
		}
		else
		{
			[obj reloadData];
		}
	}];
	
	[super updateLayerHandler];
}

- (void)noteOfSampleInsertions:(NSArray<NSNumber*>*)insertions updates:(NSArray<NSNumber*>*)updates
{
	for(DTXScatterPlotView* plotView in self.plotViews)
	{
		for (NSNumber* obj in updates) {
			[plotView reloadPointAtIndex:obj.unsignedIntegerValue];
		}
		
		[plotView addNumberOfPoints:insertions.count];
	}
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
		DTXSample* sample = _frc.fetchedObjects[idx];
		[someoneThatCan _highlightSample:sample sampleIndex:idx plotIndex:someoneThatCan == self ? plotView.plotIndex : NSNotFound positionInPlot:position valueAtClickPosition:value];
		[someoneThatCan.sampleClickDelegate plotController:someoneThatCan didClickOnSample:sample];
	}
}

#pragma mark DTXScatterPlotViewDataSource

- (NSUInteger)numberOfSamplesInPlotView:(DTXPlotView *)plotView
{
	return [self samplesForPlotIndex:plotView.plotIndex].count;
}

- (BOOL)hasAdditionalPointsForPlotView:(DTXScatterPlotView *)plotView
{
	return NO;
}

- (DTXScatterPlotViewPoint*)plotView:(DTXScatterPlotView*)plotView pointAtIndex:(NSUInteger)idx
{
	NSUInteger plotIdx = plotView.plotIndex;
	
	DTXScatterPlotViewPoint* rv = [DTXScatterPlotViewPoint new];
	rv.x = [[[self samplesForPlotIndex:plotIdx][idx] valueForKey:@"timestamp"] timeIntervalSinceReferenceDate] - [self.document.firstRecording.defactoStartTimestamp timeIntervalSinceReferenceDate];
	rv.y = [[self transformedValueForFormatter:[[self samplesForPlotIndex:plotIdx][idx] valueForKey:self.sampleKeys[plotIdx]]] doubleValue];
	
	return rv;
}

- (DTXScatterPlotViewPoint *)plotView:(DTXScatterPlotView *)plotView additionalPointAtIndex:(NSUInteger)idx
{
	return nil;
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
	[self noteOfSampleInsertions:_insertions updates:_updates];
	_insertions = nil;
	_updates = nil;
}

@end
