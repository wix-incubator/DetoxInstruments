//
//  DTXPlotHostConstructor.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXPlotHostConstructor.h"

CGFloat DTXCurrentTouchBarHeight(void)
{
	return 30;
}

@implementation DTXPlotHostConstructor

@dynamic requiredHeight;

- (instancetype)initForTouchBar:(BOOL)isForTouchBar
{
	self = [super init];
	
	if(self)
	{
		_isForTouchBar = isForTouchBar;
	}
	
	return self;
}


- (void)setUpWithView:(NSView *)view
{
	[self setUpWithView:view insets:NSEdgeInsetsMake(0, 0, 0, 0)];
}

@synthesize plotStackView=_plotStackView;
- (DTXPlotStackView *)plotStackView
{
	if(_plotStackView == nil)
	{
		_plotStackView = [DTXPlotStackView new];
		_plotStackView.translatesAutoresizingMaskIntoConstraints = NO;
		_plotStackView.orientation = NSUserInterfaceLayoutOrientationVertical;
		_plotStackView.distribution = NSStackViewDistributionFillEqually;
		_plotStackView.spacing = 0;
	}
	
	return _plotStackView;
}

- (void)setUpWithView:(NSView *)view insets:(NSEdgeInsets)insets
{
	[view.subviews enumerateObjectsUsingBlock:^(__kindof NSView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj removeFromSuperview];
	}];
	
	if(_wrapperView)
	{
		[_wrapperView removeFromSuperview];
		
		CGRect frame = view.frame;
		frame.size.height = _wrapperView.fittingSize.height;
		view.frame = frame;
		
		_wrapperView.frame = view.bounds;
	}
	else
	{
		_wrapperView = [DTXLayerView new];
		_wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
		
		BOOL usesInternalPlots = self.usesInternalPlots;
		
		if(usesInternalPlots)
		{
			[self plotStackView];
			
			[_plotStackView setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
			[_plotStackView setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
			
			if(_isForTouchBar)
			{
				[NSLayoutConstraint activateConstraints:@[
														  [_plotStackView.heightAnchor constraintEqualToConstant:DTXCurrentTouchBarHeight()],
														  ]];
			}
			else
			{
				[NSLayoutConstraint activateConstraints:@[
														  [_wrapperView.heightAnchor constraintGreaterThanOrEqualToConstant:self.requiredHeight]
														  ]];
			}
			
			[_wrapperView addSubview:_plotStackView];
			
			[NSLayoutConstraint activateConstraints:@[
													  [_wrapperView.topAnchor constraintEqualToAnchor:_plotStackView.topAnchor],
													  [_wrapperView.leadingAnchor constraintEqualToAnchor:_plotStackView.leadingAnchor],
													  [_wrapperView.trailingAnchor constraintEqualToAnchor:_plotStackView.trailingAnchor],
													  [_wrapperView.bottomAnchor constraintEqualToAnchor:_plotStackView.bottomAnchor],
													  ]];
			
			[self reloadPlotViews];
		}
#if __has_include(<CorePlot/CorePlot.h>)
		else
		{
			_hostingView = [[DTXGraphHostingView alloc] initWithFrame:view.bounds];
			_hostingView.translatesAutoresizingMaskIntoConstraints = NO;
			
			_graph = [[CPTXYGraph alloc] initWithFrame:_hostingView.bounds];
			
			_graph.paddingLeft = 0;
			_graph.paddingTop = 0;
			_graph.paddingRight = 0;
			_graph.paddingBottom = 0;
			_graph.masksToBorder  = NO;
			_graph.backgroundColor = _isForTouchBar ? NSColor.gridColor.CGColor : NSColor.clearColor.CGColor;
			
			[self setupPlotsForGraph];
			
			self.graph.plotAreaFrame.masksToBorder = NO;
			
			[self.graph.allPlots enumerateObjectsUsingBlock:^(__kindof CPTPlot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				obj.masksToBorder = NO;
				obj.backgroundColor = _isForTouchBar ? NSColor.blackColor.CGColor : NSColor.clearColor.CGColor;
			}];
			
			_hostingView.hostedGraph = _graph;
			
			[_wrapperView addSubview:_hostingView];
			
			[NSLayoutConstraint activateConstraints:@[
													  [_hostingView.heightAnchor constraintEqualToConstant:self.requiredHeight],
													  [_wrapperView.topAnchor constraintEqualToAnchor:_hostingView.topAnchor],
													  [_wrapperView.leadingAnchor constraintEqualToAnchor:_hostingView.leadingAnchor],
													  [_wrapperView.trailingAnchor constraintEqualToAnchor:_hostingView.trailingAnchor],
													  [_wrapperView.bottomAnchor constraintEqualToAnchor:_hostingView.bottomAnchor],
													  ]];
		}
#endif
	}
	
	[view addSubview:_wrapperView];
	
	[NSLayoutConstraint activateConstraints:@[
											  [view.topAnchor constraintEqualToAnchor:_wrapperView.topAnchor constant:-insets.top],
											  [view.leadingAnchor constraintEqualToAnchor:_wrapperView.leadingAnchor constant:-insets.left],
											  [view.trailingAnchor constraintEqualToAnchor:_wrapperView.trailingAnchor constant:insets.right],
											  [view.bottomAnchor constraintEqualToAnchor:_wrapperView.bottomAnchor constant:insets.bottom]
											  ]];
	
	[self didFinishViewSetup];
}

- (BOOL)usesInternalPlots
{
	return YES;
}

- (void)setupPlotViews
{
	
}

- (void)reloadPlotViews
{
	
}

- (void)setupPlotsForGraph
{
	
}

- (void)dealloc
{
#if __has_include(<CorePlot/CorePlot.h>)
	[_hostingView removeFromSuperview];
#endif
	[_wrapperView removeFromSuperview];
}

- (void)didFinishViewSetup
{
	
}

@end
