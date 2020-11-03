//
//  DTXContributorsViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 4/7/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXContributorsViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "DTXTwoLabelsCellView.h"

@interface DTXContributorsViewController () <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSTableView* _tableView;
	NSArray<NSDictionary<NSString*, NSString*>*>* _contribs;
}

@end

@implementation DTXContributorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSError* err;
	_contribs = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ContributionsGH" withExtension:@"json"]] options:0 error:&err];
	[_tableView reloadData];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	self.view.window.preventsApplicationTerminationWhenModal = NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _contribs.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
	BOOL isAnon = [[_contribs[row] valueForKeyPath:@"type"] isEqualToString:@"Anonymous"];
	NSString* name = [_contribs[row] valueForKeyPath:@"name"];
	if(isAnon)
	{
		name = [NSString stringWithFormat:@"%@ <%@>", name, [_contribs[row] valueForKeyPath:@"email"]];
	}
	
	DTXTwoLabelsCellView* cell = [tableView makeViewWithIdentifier:@"ContribCell" owner:nil];
	cell.textField.stringValue = name;
	NSInteger contribCount = [[_contribs[row] valueForKeyPath:@"total_contributions"] unsignedIntegerValue];
	cell.detailTextField.stringValue = [NSString localizedStringWithFormat:NSLocalizedString(@"%ld contributions", @""), (long)contribCount];
	NSImage* placeHolder = [NSImage imageNamed:NSImageNameUser];
	if(isAnon == NO)
	{
		[cell.imageView sd_setImageWithURL:[NSURL URLWithString:[_contribs[row] valueForKeyPath:@"avatar_url"]] placeholderImage:placeHolder];
	}
	else
	{
		[cell.imageView setImage:placeHolder];
	}
	
	cell.moreInfoButton.hidden = isAnon;
	
	return cell;
}

- (IBAction)_openGitHubPageForContributer:(id)sender
{
	NSDictionary* contrib = _contribs[[_tableView rowForView:sender]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:contrib[@"url"]]];
	[_tableView deselectAll:nil];
}

@end
