//
//  DTXRecordingTargetPickerViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteProfilingTarget-Private.h"
#import "DTXRemoteProfilingTargetCellView.h"
#import "DTXRemoteProfilingBasics.h"

@interface DTXRecordingTargetPickerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, DTXSocketConnectionDelegate>
{
	IBOutlet NSOutlineView* _outlineView;
	
	NSNetServiceBrowser* _browser;
	NSMutableArray<DTXRemoteProfilingTarget*>* _targets;
	NSMapTable<NSNetService*, DTXRemoteProfilingTarget*>* _serviceToTargetMapping;
	NSMapTable<DTXRemoteProfilingTarget*, NSNetService*>* _targetToServiceMapping;
	NSMapTable<DTXSocketConnection*, DTXRemoteProfilingTarget*>* _connectionToTargetMapping;
	
	dispatch_queue_t _workQueue;
}

@end

@implementation DTXRecordingTargetPickerViewController

+ (NSData*)_dataForNetworkCommand:(NSDictionary*)cmd
{
	return [NSPropertyListSerialization dataWithPropertyList:cmd format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
}

+ (NSDictionary*)_responseFromNetworkData:(NSData*)data
{
	return [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.wantsLayer = YES;
	self.view.canDrawSubviewsIntoLayer = YES;
	
	_targets = [NSMutableArray new];
	_serviceToTargetMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	_targetToServiceMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	_connectionToTargetMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
	_workQueue = dispatch_queue_create("com.wix.DTXRemoteProfiler", qosAttribute);
	
	_browser = [NSNetServiceBrowser new];
	_browser.delegate = self;
	
	[_browser searchForServicesOfType:@"_detoxprofiling._tcp" inDomain:@""];
}

- (IBAction)cancel:(id)sender
{
	[self.delegate recordingTargetPickerDidCancel:self];
}

- (void)_addTarget:(DTXRemoteProfilingTarget*)target forService:(NSNetService*)service
{
	[_serviceToTargetMapping setObject:target forKey:service];
	[_targetToServiceMapping setObject:service forKey:target];
	[_targets addObject:target];
	
	[_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:_targets.count - 1] inParent:nil withAnimation:NSTableViewAnimationEffectFade];
}

- (void)_removeTargetForService:(NSNetService*)service
{
	DTXRemoteProfilingTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target == nil)
	{
		return;
	}
	
	NSInteger index = [_targets indexOfObject:target];
	
	if(index == NSNotFound)
	{
		return;
	}
	
	[_targets removeObjectAtIndex:index];
	[_serviceToTargetMapping removeObjectForKey:service];
	[_targetToServiceMapping removeObjectForKey:target];
	if(target.connection != nil)
	{
		[_connectionToTargetMapping removeObjectForKey:target.connection];
	}
	
	[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectFade];
}

- (void)_updateTarget:(DTXRemoteProfilingTarget*)target
{
//	[_outlineView reloadData];
	[_outlineView reloadItem:target];
}

- (void)_loadDetailsForTarget:(DTXRemoteProfilingTarget*)target
{
	[target.connection writeData:[DTXRecordingTargetPickerViewController _dataForNetworkCommand:@{@"cmdType": @(DTXRemoteProfilingCommandTypeInfo)}] completionHandler:^(NSError * _Nullable error) {
		[target.connection readDataWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
			if(data == nil)
			{
				dispatch_async(dispatch_get_main_queue(), ^ {
					[self _removeTargetForService:[_targetToServiceMapping objectForKey:target]];
				});
				
				return;
			}
			
			NSDictionary* dict = [DTXRecordingTargetPickerViewController _responseFromNetworkData:data];
			
			dispatch_async(dispatch_get_main_queue(), ^ {
				target.deviceName = dict[@"deviceName"];
				target.applicationName = dict[@"appName"];
				target.operatingSystemVersion = dict[@"osVersion"];
				target.state = 2;
				
				[self _updateTarget:target];
			});
		}];
	}];
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	service.delegate = self;
	
	DTXRemoteProfilingTarget* target = [DTXRemoteProfilingTarget new];
	[self _addTarget:target forService:service];
	
	[service resolveWithTimeout:10];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	DTXRemoteProfilingTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target.state < 1)
	{
		[self _removeTargetForService:service];
	}
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DTXRemoteProfilingTarget* target = [_serviceToTargetMapping objectForKey:sender];
	target.state = 1;
	target.hostName = sender.hostName;
	target.port = sender.port;
	target.connection = [[DTXSocketConnection alloc] initWithHostName:sender.hostName port:sender.port queue:_workQueue];
	target.connection.delegate = self;
	
	[_connectionToTargetMapping setObject:target forKey:target.connection];
	
	[target.connection open];
	
	[self _loadDetailsForTarget:target];
	
	[self _updateTarget:target];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	[self _removeTargetForService:sender];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item != nil)
	{
		return 0;
	}
	
	return _targets.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	return _targets[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

#pragma mark NSOutlineViewDelegate

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	DTXRemoteProfilingTarget* target = item;
	
	DTXRemoteProfilingTargetCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXRemoteProfilingTargetCellView" owner:nil];
	cellView.progressIndicator.usesThreadedAnimation = YES;
	
	switch(target.state)
	{
		case 0:
		case 1:
			cellView.title1Field.stringValue = @"";
			cellView.title2Field.stringValue = target.state == 0 ? NSLocalizedString(@"Discovering...", @"") : NSLocalizedString(@"Loading...", @"");
			cellView.title3Field.stringValue = @"";
			cellView.deviceImageView.hidden = YES;
			[cellView.progressIndicator startAnimation:nil];
			cellView.progressIndicator.hidden = NO;
			break;
		case 2:
			cellView.title1Field.stringValue = target.deviceName;
			cellView.title2Field.stringValue = target.applicationName;
			cellView.title3Field.stringValue = target.operatingSystemVersion;
			cellView.deviceImageView.hidden = NO;
			[cellView.progressIndicator stopAnimation:nil];
			cellView.progressIndicator.hidden = YES;
			break;
	}
	
	return cellView;
}

#pragma mark DTXSocketConnectionDelegate

- (void)readClosedForSocketConnection:(DTXSocketConnection*)socketConnection;
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self _removeTargetForService:[_targetToServiceMapping objectForKey:[_connectionToTargetMapping objectForKey:socketConnection]]];
	});
}

- (void)writeClosedForSocketConnection:(DTXSocketConnection*)socketConnection
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self _removeTargetForService:[_targetToServiceMapping objectForKey:[_connectionToTargetMapping objectForKey:socketConnection]]];
	});
}

@end
