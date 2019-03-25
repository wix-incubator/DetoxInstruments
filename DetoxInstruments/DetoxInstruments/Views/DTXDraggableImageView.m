//
//  DTXDraggableImageView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/21/19.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXDraggableImageView.h"

@implementation DTXDraggableImageView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	if([sender.draggingPasteboard canReadObjectForClasses:@[NSURL.class] options:nil] == NO || sender.numberOfValidItemsForDrop != 1)
	{
		return NSDragOperationNone;
	}
	
	NSURL* dragged = [sender.draggingPasteboard readObjectsForClasses:@[NSURL.class] options:nil].firstObject;
	NSNumber* isDir = @YES;
	[dragged getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:NULL];
	return isDir.boolValue ? NSDragOperationNone : (NSDragOperationGeneric | NSDragOperationCopy);
}

-(void)draggingEnded:(id<NSDraggingInfo>)sender
{
	
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
	
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
	NSURL* dragged = [sender.draggingPasteboard readObjectsForClasses:@[NSURL.class] options:nil].firstObject;
	
	[self.dragDelegate draggableImageView:self didAcceptURL:dragged];
}

@end
