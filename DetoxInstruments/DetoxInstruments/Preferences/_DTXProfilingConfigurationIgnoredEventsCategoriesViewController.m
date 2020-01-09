//
//  _DTXProfilingConfigurationIgnoredEventsCategoriesViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/27/18.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "_DTXProfilingConfigurationIgnoredEventsCategoriesViewController.h"
#import "DTXTableEditingArrayController.h"

@interface _DTXIgnoredCategory : NSObject
@property (nonatomic, copy) NSString* category;
@end
@implementation _DTXIgnoredCategory
- (instancetype)init
{
	self = [super init];
	if(self) { self.category = @"Category"; }
	return self;
}
+ (instancetype)categoryWithCategory:(NSString*)category
{
	_DTXIgnoredCategory* rv = [self new];
	if(self) { rv.category = category; }
	return rv;
}
@end

@interface _DTXProfilingConfigurationIgnoredEventsCategoriesViewController () <NSTableViewDelegate>

@property (nonatomic, copy) NSMutableArray<_DTXIgnoredCategory*>* categories;

@end

@implementation _DTXProfilingConfigurationIgnoredEventsCategoriesViewController
{
	IBOutlet DTXTableEditingArrayController* _arrayController;
	IBOutlet NSTableView* _tableView;
	NSArray* _beforeEditing;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.categories = self._serializedCategories;
	_beforeEditing = self.categories.copy;
	_arrayController.tableView = _tableView;
	
	[_arrayController addObserver:self forKeyPath:@"arrangedObjects.@count" options:NSKeyValueObservingOptionNew context:NULL];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_textDidEndEditing:) name:NSTextDidEndEditingNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	[self _serializeCategories];
}

- (IBAction)cancel:(id)sender
{
	self.categories = _beforeEditing.mutableCopy;
	[self _serializeCategories];
	[self dismissController:sender];
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self name:NSTextDidEndEditingNotification object:nil];
}

- (void)_textDidEndEditing:(NSNotification*)note
{	
	if(((NSView*)note.object).window != _tableView.window)
	{
		return;
	}
	
	[self _serializeCategories];
}

- (NSMutableArray*)_serializedCategories
{
	NSArray<NSString*>* categories = [[NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"] ?: @[] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray* rv = [NSMutableArray new];
	
	[categories enumerateObjectsUsingBlock:^(NSString* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:[_DTXIgnoredCategory categoryWithCategory:obj]];
	}];
	
	return rv;
}

- (void)_serializeCategories
{
	[NSUserDefaults.standardUserDefaults setObject:[self.categories valueForKeyPath:@"@distinctUnionOfObjects.category"] forKey:@"DTXSelectedProfilingConfiguration__ignoredEventCategoriesArray"];
}

@end
