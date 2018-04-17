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
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "_DTXTargetsOutlineViewContoller.h"
#import "_DTXProfilingConfigurationViewController.h"
#import "_DTXContainerContentsOutlineViewController.h"
#import "_DTXUserDefaultsOutlineViewController.h"

@import QuartzCore;

@interface DTXRecordingTargetPickerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, DTXRemoteProfilingTargetDelegate>
{
	IBOutlet NSView* _containerView;
	IBOutlet NSStackView* _actionButtonStackView;
	
	_DTXTargetsOutlineViewContoller* _outlineController;
	NSOutlineView* _outlineView;
	
	DTXRemoteProfilingTarget* _inspectedTarget;
	_DTXProfilingConfigurationViewController* _profilingConfigurationController;
	_DTXContainerContentsOutlineViewController* _containerContentsOutlineViewController;
	_DTXUserDefaultsOutlineViewController* _userDefaultsViewController;
	NSViewController<_DTXActionButtonProvider>* _activeController;
	
	IBOutlet NSButton* _cancelButton;
	
	NSNetServiceBrowser* _browser;
	NSMutableArray<DTXRemoteProfilingTarget*>* _targets;
	NSMapTable<NSNetService*, DTXRemoteProfilingTarget*>* _serviceToTargetMapping;
	NSMapTable<DTXRemoteProfilingTarget*, NSNetService*>* _targetToServiceMapping;
	
	dispatch_queue_t _workQueue;
	
	IBOutlet NSMenu* _appManageMenu;
}

@end

@implementation DTXRecordingTargetPickerViewController

- (void)_pinView:(NSView*)view toView:(NSView*)view2
{
	[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:view2.topAnchor],
											  [view.bottomAnchor constraintEqualToAnchor:view2.bottomAnchor],
											  [view.leftAnchor constraintEqualToAnchor:view2.leftAnchor],
											  [view.rightAnchor constraintEqualToAnchor:view2.rightAnchor]]];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_containerView.wantsLayer = YES;
	
	_outlineController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXTargetsOutlineViewContoller"];
	[self addChildViewController:_outlineController];
	[_outlineController view];
	
	_outlineView = _outlineController.outlineView;
	_outlineView.dataSource = self;
	_outlineView.delegate = self;
	_outlineView.doubleAction = @selector(_doubleClicked:);
	
	_profilingConfigurationController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXProfilingConfigurationViewController"];
	[self addChildViewController:_profilingConfigurationController];
	
	_containerContentsOutlineViewController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXContainerContentsOutlineViewController"];
	[self addChildViewController:_containerContentsOutlineViewController];
	
	_userDefaultsViewController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXUserDefaultsOutlineViewController"];
	[self addChildViewController:_userDefaultsViewController];
	
	[_profilingConfigurationController view];
	[_containerContentsOutlineViewController view];
	[_userDefaultsViewController view];
	
	[_containerView addSubview:_outlineController.view];
	
	[self _setupActionButtonsWithProvider:_outlineController];
	_activeController = _outlineController;
	[self _validateSelectButton];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	self.view.wantsLayer = YES;
	self.view.canDrawSubviewsIntoLayer = YES;
	_containerView.wantsLayer = YES;
	
	_targets = [NSMutableArray new];
	_serviceToTargetMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	_targetToServiceMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
	_workQueue = dispatch_queue_create("com.wix.DTXRemoteProfiler", qosAttribute);
	
	_browser = [NSNetServiceBrowser new];
	_browser.delegate = self;
	
	[_browser searchForServicesOfType:@"_detoxprofiling._tcp" inDomain:@""];
}

- (IBAction)selectButtonClicked:(id)sender
{
	if(_outlineView.selectedRow == -1)
	{
		return;
	}
	
	DTXRemoteProfilingTarget* target = _targets[_outlineView.selectedRow];
	
	if(target.state != DTXRemoteProfilingTargetStateDeviceInfoLoaded)
	{
		return;
	}
	
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration profilingConfigurationForRemoteProfilingFromDefaults];
	
	[self.delegate recordingTargetPicker:self didSelectRemoteProfilingTarget:_targets[_outlineView.selectedRow] profilingConfiguration:config];
}

- (IBAction)cancel:(id)sender
{
	if(_activeController != _outlineController)
	{
		[self _transitionToController:_outlineController];
		
		return;
	}
	
	[self.delegate recordingTargetPickerDidCancel:self];
}

- (IBAction)options:(id)sender
{
	[self _transitionToController:_profilingConfigurationController];
}

- (void)_setupActionButtonsWithProvider:(id<_DTXActionButtonProvider>)provider
{
	[provider.actionButtons enumerateObjectsUsingBlock:^(NSButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
		button.translatesAutoresizingMaskIntoConstraints = NO;
		[_actionButtonStackView insertArrangedSubview:button atIndex:0];
		if(button.bezelStyle != NSBezelStyleHelpButton && [button.title isEqualToString:@"Refresh"] == NO)
		{
			[NSLayoutConstraint activateConstraints:@[[button.widthAnchor constraintEqualToAnchor:_cancelButton.widthAnchor]]];
		}
	}];
}

- (void)_removeActionButtonsWithProvider:(id<_DTXActionButtonProvider>)provider
{
	[provider.actionButtons enumerateObjectsUsingBlock:^(NSButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
		[_actionButtonStackView removeView:button];
	}];
}

- (void)_transitionToController:(NSViewController<_DTXActionButtonProvider>*)controller
{
	NSViewControllerTransitionOptions transitionOptions = NSViewControllerTransitionSlideForward;
	if(controller == _outlineController)
	{
		transitionOptions = NSViewControllerTransitionSlideBackward;
		_cancelButton.title = NSLocalizedString(@"Cancel", @"");
		_inspectedTarget = nil;
	}
	else
	{
		_cancelButton.title = NSLocalizedString(@"Back", @"");
	}
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.3;
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		[self _removeActionButtonsWithProvider:_activeController];
		[self _setupActionButtonsWithProvider:controller];
		
		[self transitionFromViewController:_activeController toViewController:controller options:transitionOptions completionHandler:nil];
	} completionHandler:nil];
	
	_activeController = controller;
	
	[self _validateSelectButton];
}

- (void)_addTarget:(DTXRemoteProfilingTarget*)target forService:(NSNetService*)service
{
	[_serviceToTargetMapping setObject:target forKey:service];
	[_targetToServiceMapping setObject:service forKey:target];
	[_targets addObject:target];
	
	NSIndexSet* itemIndexSet = [NSIndexSet indexSetWithIndex:_targets.count - 1];
	[_outlineView beginUpdates];
	[_outlineView insertItemsAtIndexes:itemIndexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
	[_outlineView endUpdates];
	if(itemIndexSet.firstIndex == 0)
	{
		[_outlineView selectRowIndexes:itemIndexSet byExtendingSelection:NO];
	}
}

- (void)_removeTargetForService:(NSNetService*)service
{
	DTXRemoteProfilingTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target == nil)
	{
		[_outlineView reloadData];
		
		[self _transitionToController:_outlineController];
		
		return;
	}
	
	if(target == _inspectedTarget)
	{
		[self _transitionToController:_outlineController];
	}
	
	NSInteger index = [_targets indexOfObject:target];
	
	if(index == NSNotFound)
	{
		[_outlineView reloadData];
		
		return;
	}
	
	[_targets removeObjectAtIndex:index];
	[_serviceToTargetMapping removeObjectForKey:service];
	[_targetToServiceMapping removeObjectForKey:target];
	
	[_outlineView beginUpdates];
	[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectFade];
	[_outlineView endUpdates];
}

- (void)_updateTarget:(DTXRemoteProfilingTarget*)target
{
	[_outlineView reloadItem:target];
}

- (IBAction)_manageMenuButtonClicked:(NSButton*)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	id target = _targets[row];
	
	[_appManageMenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.representedObject = target;
	}];
	
	[_appManageMenu popUpMenuPositioningItem:_appManageMenu.itemArray.firstObject atLocation:NSMakePoint(30, 30) inView:sender];
}

- (void)_clearRepresentedItemsFromMenu
{
	[_appManageMenu.itemArray enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.representedObject = nil;
	}];
}

- (IBAction)_containerContents:(NSMenuItem*)sender
{
	_inspectedTarget = sender.representedObject;
	_containerContentsOutlineViewController.profilingTarget = _inspectedTarget;
	[self _transitionToController:_containerContentsOutlineViewController];
	
	[self _clearRepresentedItemsFromMenu];
}

- (IBAction)_userDefaults:(NSMenuItem*)sender
{
	_inspectedTarget = sender.representedObject;
	_userDefaultsViewController.profilingTarget = _inspectedTarget;
	[self _transitionToController:_userDefaultsViewController];
	
	[self _clearRepresentedItemsFromMenu];
}

- (IBAction)_doubleClicked:(id)sender
{
	if(_outlineView.clickedRow == -1)
	{
		return;
	}
	
	DTXRemoteProfilingTarget* target = _targets[_outlineView.clickedRow];
	
	if(target.state != DTXRemoteProfilingTargetStateDeviceInfoLoaded)
	{
		return;
	}
	
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration profilingConfigurationForRemoteProfilingFromDefaults];
	
	[self.delegate recordingTargetPicker:self didSelectRemoteProfilingTarget:_targets[_outlineView.selectedRow] profilingConfiguration:config];
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
	[cellView updateFeatureSetWithProfilerVersion:target.deviceInfo[@"profilerVersion"]];
	
	switch(target.state)
	{
		case DTXRemoteProfilingTargetStateDiscovered:
		case DTXRemoteProfilingTargetStateResolved:
			cellView.title1Field.stringValue = @"";
			cellView.title2Field.stringValue = target.state == DTXRemoteProfilingTargetStateDiscovered ? NSLocalizedString(@"Resolving...", @"") : NSLocalizedString(@"Loading...", @"");
			cellView.title3Field.stringValue = @"";
			cellView.deviceImageView.hidden = YES;
			[cellView.progressIndicator startAnimation:nil];
			cellView.progressIndicator.hidden = NO;
			break;
		case DTXRemoteProfilingTargetStateDeviceInfoLoaded:
		{
			cellView.title1Field.stringValue = target.appName;
			cellView.title2Field.stringValue = target.deviceName;
			cellView.title3Field.stringValue = [NSString stringWithFormat:@"iOS %@", [target.deviceOS stringByReplacingOccurrencesOfString:@"Version " withString:@""]];
			cellView.deviceImageView.hidden = NO;
			[cellView.progressIndicator stopAnimation:nil];
			cellView.progressIndicator.hidden = YES;
			cellView.deviceSnapshotImageView.image = target.deviceSnapshot;
			
			NSArray<NSString*>* xSuffix = @[@"10,3", @"10,6"];
			__block BOOL hasNotch = false;
			[xSuffix enumerateObjectsUsingBlock:^(NSString* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				hasNotch = hasNotch || [target.deviceInfo[@"machineName"] hasSuffix:obj];
			}];
			
			NSString* devicePrefix = [target.deviceInfo[@"machineName"] hasPrefix:@"iPhone"] ? @"device_iphone" : @"device_ipad";
			NSString* deviceEnclosureColor = target.deviceInfo[@"deviceEnclosureColor"];
			NSString* imageName = [NSString stringWithFormat:@"%@_%@%@", devicePrefix, hasNotch ? @"x_" : @"", deviceEnclosureColor];
			
			NSImage* image = [NSImage imageNamed:imageName] ?: [NSImage imageNamed:@"device_iphone_x_2"];;
			
			cellView.deviceImageView.image = image;
			
		}	break;
		default:
			break;
	}
	
	return cellView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self _validateSelectButton];
}

- (void)_validateSelectButton
{
	_outlineController.selectButton.enabled = _outlineView.selectedRowIndexes.count > 0;
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DTXRemoteProfilingTarget* target = [_serviceToTargetMapping objectForKey:sender];
	target.delegate = self;
	
	[target _connectWithHostName:sender.hostName port:sender.port workQueue:_workQueue];
	
	[target loadDeviceInfo];
	
	[self _updateTarget:target];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	[self _removeTargetForService:sender];
}

#pragma mark DTXRemoteProfilingTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteProfilingTarget*)target
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self _removeTargetForService:[_targetToServiceMapping objectForKey:target]];
	});
}

- (void)profilingTargetDidLoadDeviceInfo:(DTXRemoteProfilingTarget *)target
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _updateTarget:target];
	});
}

- (void)profilingTargetdidLoadContainerContents:(DTXRemoteProfilingTarget *)target
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_containerContentsOutlineViewController noteProfilingTargetDidLoadServiceData];
	});
}

- (void)profilingTarget:(DTXRemoteProfilingTarget *)target didDownloadContainerContents:(NSData *)containerContents wasZipped:(BOOL)wasZipped
{
	if(containerContents.length == 0)
	{
		//TODO: Display error
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if(target != _inspectedTarget)
		{
			return;
		}
		
		[_containerContentsOutlineViewController showSaveDialogForSavingData:containerContents dataWasZipped:wasZipped];
	});
}

- (void)profilingTarget:(DTXRemoteProfilingTarget *)target didLoadUserDefaults:(NSDictionary *)userDefaults
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_userDefaultsViewController noteProfilingTargetDidLoadServiceData];
	});
}

@end
