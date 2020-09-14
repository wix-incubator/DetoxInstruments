//
//  DTXLiveLogViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/27/20.
//  Copyright © 2020 Wix. All rights reserved.
//

#import "DTXLiveLogViewController.h"
#import "DTXLiveLogEntry+CoreDataProperties.h"
#import "DTXShortDateValueTransformer.h"
#import "DTXLogSample+UIExtensions.h"
#import "NSView+UIAdditions.h"
@import CoreData;

@interface DTXLiveLogViewController () <NSTableViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext* context;
@property (nonatomic, strong) NSPredicate* scopePredicate;
@property (nonatomic, strong) NSPredicate* levelPredicate;
@property (nonatomic, strong) NSPredicate* applePredicate;

@end

@implementation DTXLiveLogViewController
{
	NSPersistentContainer* _container;
	NSManagedObjectContext* _bgContext;
	
	IBOutlet NSTableView* _tableView;
	IBOutlet NSArrayController* _arrayController;
	
	IBOutlet NSTextField* _processTextField;
	IBOutlet NSTextField* _subsystemTextField;
	IBOutlet NSTextField* _categoryTextField;
	IBOutlet NSTextField* _typeTextField;
	IBOutlet NSTextField* _dateTextField;
	IBOutlet NSTextView* _messageTextView;
	
	NSDateFormatter* _dateTransformer;
	NSNumberFormatter* _numberFormatter;
	
	BOOL _scrollingToBottom;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_dateTransformer = [NSDateFormatter new];
	_dateTransformer.timeStyle = NSDateFormatterMediumStyle;
	_dateTransformer.dateStyle = NSDateFormatterMediumStyle;
	
	_numberFormatter = [NSNumberFormatter new];
	_numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	
	_tableView.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	
	_levelPredicate = [NSPredicate predicateWithValue:YES];
	_scopePredicate = [NSPredicate predicateWithValue:YES];
	_applePredicate = [NSPredicate predicateWithValue:YES];
	
	[_tableView.enclosingScrollView.contentView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tableViewDidScroll:) name:NSViewBoundsDidChangeNotification object:_tableView.enclosingScrollView.contentView];
	
	_scrollingToBottom = YES;
	_nowMode = YES;
}

- (void)_scrollToBottom
{
	_scrollingToBottom = YES;
	[_tableView scrollToBottom];
	_scrollingToBottom = NO;
}

- (void)_tableViewDidScroll:(NSNotification*)note
{
	if(_scrollingToBottom == YES)
	{
		return;
	}
	
	self.nowMode = NO;
}

- (void)setProfilingTarget:(DTXRemoteTarget *)profilingTarget
{
	_profilingTarget = profilingTarget;
	
	[self _reloadWindowTitle];
}

- (void)_reloadWindowTitle
{
	NSString* messages = [NSString stringWithFormat:@"%@ messages", [_numberFormatter stringFromNumber:@(_tableView.numberOfRows)]];
	
	if (@available(macOS 11.0, *))
	{
		self.view.window.title = self.profilingTarget.deviceName ?: @"";
		self.view.window.subtitle = messages;
	}
	else
	{
		self.view.window.title = [NSString stringWithFormat:@"%@ (%@)", self.profilingTarget.deviceName, messages];
	}
}

- (void)setNowMode:(BOOL)nowMode
{
	if(self.nowMode == nowMode)
	{
		return;
	}
	
	[self willChangeValueForKey:@"nowMode"];
	
	_nowMode = nowMode;
	
	[self didChangeValueForKey:@"nowMode"];
	
	if(self.nowMode)
	{
		[self _scrollToBottom];
	}
}

- (void)viewWillAppear
{
	[super viewWillAppear];
	
	_scrollingToBottom = YES;
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	static NSManagedObjectModel* model;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle bundleForClass:DTXLiveLogEntry.class] URLForResource:@"LiveConsoleModel" withExtension:@"momd"]];
	});
	
	_container = [[NSPersistentContainer alloc] initWithName:@"LiveConsoleModel" managedObjectModel:model];
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription new];
	description.type = NSInMemoryStoreType;
	_container.persistentStoreDescriptions = @[description];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		self.context = _container.viewContext;
		self.context.automaticallyMergesChangesFromParent = YES;
	}];
	
	NSManagedObjectContext* bg = _container.newBackgroundContext;
	[self.profilingTarget startStreamingLogsWithHandler:^(BOOL isFromAppProcess, NSString* processName, BOOL isFromApple, NSDate *timestamp, DTXProfilerLogLevel level, NSString *subsystem, NSString *category, NSString *message) {
		[self.context performBlock:^{
			DTXLiveLogEntry* entry = [[DTXLiveLogEntry alloc] initWithContext:self.context];
			entry.isFromAppProcess = isFromAppProcess;
			entry.isFromApple = isFromApple;
			entry.process = processName;
			entry.timestamp = timestamp;
			entry.level = level;
			entry.subsystem = subsystem;
			entry.category = category;
			entry.message = message;
			
			[self.context save:NULL];
			
			if(self.nowMode)
			{
				[self _scrollToBottom];
			}
			
			[self _reloadWindowTitle];
		}];
	}];
	
	[self _reloadWindowTitle];
	
	self.nowMode = YES;
	_scrollingToBottom = NO;
}

- (void)viewDidDisappear
{
	[self.profilingTarget stopStreamingLogs];
	self.context = nil;
	_container = nil;
}

- (IBAction)clearLog:(id)sender
{
	NSArray<DTXLiveLogEntry*>* objects = [self.context executeFetchRequest:DTXLiveLogEntry.fetchRequest error:NULL];
	for (DTXLiveLogEntry* entry in objects) {
		[self.context deleteObject:entry];
	}
	[self.context save:NULL];
	[self _loadEntry:nil];
	
	self.nowMode = YES;
	
	[self _reloadWindowTitle];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	self.nowMode = NO;
	
	DTXLiveLogEntry* entry = _arrayController.selectedObjects.firstObject;
	
	[self _loadEntry:entry];
}

- (void)_loadEntry:(DTXLiveLogEntry*)entry
{
	_processTextField.stringValue = entry.process.length > 0 ? entry.process : @"—";
	_subsystemTextField.stringValue = entry.subsystem.length > 0 ? entry.subsystem : @"—";
	_categoryTextField.stringValue = entry.category.length > 0 ? entry.category : @"—";
	NSColor* logLevelColor = DTXLogLevelColor(entry.level);
	_typeTextField.stringValue = entry ? DTXLogLevelDescription(entry.level, YES) : @"—";
	_typeTextField.wantsLayer = YES;
	_typeTextField.layer.backgroundColor = logLevelColor.CGColor;
	_typeTextField.layer.cornerRadius = 3.0;
	if(logLevelColor == nil)
	{
		_typeTextField.textColor = NSColor.labelColor;
	}
	else if(entry.level == DTXProfilerLogLevelError || entry.level == DTXProfilerLogLevelNotice)
	{
		_typeTextField.textColor = NSColor.blackColor;
	}
	else
	{
		_typeTextField.textColor = NSColor.whiteColor;
	}
	_dateTextField.stringValue = [_dateTransformer stringFromDate:entry.timestamp] ?: @"—";
	_messageTextView.string = entry.message ?: @"";
	_messageTextView.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
}

- (void)setScopePredicate:(NSPredicate *)scopePredicate
{
	_scopePredicate = scopePredicate;
	
	[self _updateFetchPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[_levelPredicate, _scopePredicate, _applePredicate]]];
}

- (void)setLevelPredicate:(NSPredicate *)levelPredicate
{
	_levelPredicate = levelPredicate;

	[self _updateFetchPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[_levelPredicate, _scopePredicate, _applePredicate]]];
}

- (void)setApplePredicate:(NSPredicate *)applePredicate
{
	_applePredicate = applePredicate;
	
	[self _updateFetchPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[_levelPredicate, _scopePredicate, _applePredicate]]];
}

- (void)_updateFetchPredicate:(NSPredicate*)predicate
{
	_arrayController.fetchPredicate = predicate;
	
	[self _reloadWindowTitle];
	self.nowMode = YES;
}

#pragma mark DTXFilterAccessoryControllerDelegate

- (void)allProcesses:(BOOL)allProcesses
{
	self.scopePredicate = !allProcesses ? [NSPredicate predicateWithFormat:@"isFromAppProcess == YES"] : [NSPredicate predicateWithValue:YES];
}

- (void)allMessages:(BOOL)allMessages
{
	self.levelPredicate = !allMessages ? [NSPredicate predicateWithFormat:@"level in %@", @[@(DTXProfilerLogLevelError), @(DTXProfilerLogLevelFault)]] : [NSPredicate predicateWithValue:YES];
}

- (void)includeApple:(BOOL)includeApple
{
	self.applePredicate = !includeApple ? [NSPredicate predicateWithFormat:@"isFromApple == NO"] : [NSPredicate predicateWithValue:YES];
}

@end
