//
//  DTXHeaderView.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 07/06/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXHeaderView.h"
#import "NSColor+UIAdditions.h"

@implementation DTXHeaderView
{
	__weak IBOutlet NSTableView* _tableView;
}

- (BOOL)canDrawConcurrently
{
	return YES;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
}

- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	
	[self viewDidChangeBackingProperties];
}

-(void)viewDidChangeBackingProperties
{
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	[NSColor.gridColor set];
	
	NSBezierPath* line = [NSBezierPath bezierPath];

	[line moveToPoint:NSMakePoint(0, 0.5)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width, 0.5)];
	
	[line moveToPoint:NSMakePoint(_tableView.tableColumns.firstObject.width + 0.5, 1)];
	[line lineToPoint:NSMakePoint(_tableView.tableColumns.firstObject.width + 0.5, self.bounds.size.height)];
	
	line.lineWidth = 1;
	[line stroke];
}

@end
