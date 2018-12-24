//
//  ViewController.m
//  DrawTest
//
//  Created by Leo Natan (Wix) on 12/20/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
	IBOutlet NSTableView* _tableView;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_tableView.usesAutomaticRowHeights = YES;
}


- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 3;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	return @0;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:@"Cell" owner:nil];
}

@end
