//
//  DTXDraggableImageView.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/21/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DTXDraggableImageView;

@protocol DTXDraggableImageViewDelegate <NSObject>

- (void)draggableImageView:(DTXDraggableImageView*)imageView didAcceptURL:(NSURL*)URL;

@end

@interface DTXDraggableImageView : NSImageView

@property (nonatomic, weak) IBOutlet id<DTXDraggableImageViewDelegate> dragDelegate;

@end
