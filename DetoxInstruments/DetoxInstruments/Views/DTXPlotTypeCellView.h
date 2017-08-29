//
//  DTXPlotTypeCellView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 19/06/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXHighlightingCellView.h"

@interface DTXPlotTypeCellView : DTXHighlightingCellView

@property (nonatomic, strong, readonly) NSImageView* secondaryImageView;

@property (nonatomic, strong, readonly) NSTextField* topLegendTextField;
@property (nonatomic, strong, readonly) NSTextField* bottomLegendTextField;

@end
