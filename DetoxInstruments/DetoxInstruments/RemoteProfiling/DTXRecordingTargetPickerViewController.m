//
//  DTXRecordingTargetPickerViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteTarget-Private.h"
#import "DTXRemoteTargetCellView.h"
#import "DTXRemoteProfilingBasics.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "_DTXTargetsOutlineViewContoller.h"
#import "_DTXProfilingConfigurationViewController.h"
#import "DTXProfilingTargetManagementWindowController.h"

@import QuartzCore;

@interface DTXRecordingTargetPickerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, DTXRemoteTargetDelegate, NSPopoverDelegate>
{
	IBOutlet NSView* _containerView;
	IBOutlet NSStackView* _actionButtonStackView;
	
	_DTXTargetsOutlineViewContoller* _outlineController;
	NSOutlineView* _outlineView;
	
	_DTXProfilingConfigurationViewController* _profilingConfigurationController;
	NSViewController<_DTXActionButtonProvider>* _activeController;
	
	IBOutlet NSButton* _cancelButton;
	
	NSNetServiceBrowser* _browser;
	NSMutableArray<DTXRemoteTarget*>* _targets;
	NSMapTable<NSNetService*, DTXRemoteTarget*>* _serviceToTargetMapping;
	NSMapTable<DTXRemoteTarget*, NSNetService*>* _targetToServiceMapping;
	
	dispatch_queue_t _workQueue;
	
	NSMapTable<DTXRemoteTarget*, DTXProfilingTargetManagementWindowController*>* _targetManagementControllers;
	
	NSPopover* _warningPopover;
}

@end

@implementation DTXRecordingTargetPickerViewController

- (void)_pinView:(NSView*)view toView:(NSView*)view2
{
	[NSLayoutConstraint activateConstraints:@[[view.topAnchor constraintEqualToAnchor:view2.topAnchor],
											  [view.bottomAnchor constraintEqualToAnchor:view2.bottomAnchor],
											  [view.leadingAnchor constraintEqualToAnchor:view2.leadingAnchor],
											  [view.trailingAnchor constraintEqualToAnchor:view2.trailingAnchor]]];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_containerView.wantsLayer = YES;
	_containerView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	_outlineController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXTargetsOutlineViewContoller"];
	[self addChildViewController:_outlineController];
	[_outlineController view];
	
	_outlineView = _outlineController.outlineView;
	_outlineView.dataSource = self;
	_outlineView.delegate = self;
	_outlineView.doubleAction = @selector(_doubleClicked:);
	
	_profilingConfigurationController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXProfilingConfigurationViewController"];
	[self addChildViewController:_profilingConfigurationController];
	
	[_profilingConfigurationController view];
	
	[_containerView addSubview:_outlineController.view];
	
	[self _setupActionButtonsWithProvider:_outlineController];
	_activeController = _outlineController;
	[self _validateSelectButton];
	
	_targets = [NSMutableArray new];
	_serviceToTargetMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	_targetToServiceMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	_containerView.wantsLayer = YES;
	_containerView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
	_workQueue = dispatch_queue_create("com.wix.DTXRemoteProfiler", qosAttribute);
	
	_browser = [NSNetServiceBrowser new];
	_browser.delegate = self;
	
	_targetManagementControllers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	self.view.window.preventsApplicationTerminationWhenModal = NO;
	
	[_browser searchForServicesOfType:@"_detoxprofiling._tcp" inDomain:@""];
}

- (IBAction)selectProfilingTarget:(id)sender
{
	if(_outlineView.selectedRow == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = _targets[_outlineView.selectedRow];
	
	if(target.state != DTXRemoteTargetStateDeviceInfoLoaded)
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

- (void)_addTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service
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
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target == nil)
	{
		[_outlineView reloadData];
		
		return;
	}
	
	[[_targetManagementControllers objectForKey:target] dismissPreferencesWindow];
	[_targetManagementControllers removeObjectForKey:target];
	
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

- (void)_updateTarget:(DTXRemoteTarget*)target
{
	[_outlineView reloadItem:target];
}

- (IBAction)_manageProfilingTarget:(NSButton*)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		return;
	}
	
	id target = _targets[row];
	
	DTXProfilingTargetManagementWindowController* targetManagement = [_targetManagementControllers objectForKey:target];
	if(targetManagement == nil)
	{
		targetManagement = [DTXProfilingTargetManagementWindowController new];
		[targetManagement setProfilingTarget:target];
		[_targetManagementControllers setObject:targetManagement forKey:target];
	}

	[targetManagement showPreferencesWindow];
}

- (IBAction)_captureViewHierarchy:(id)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = _targets[row];
	
	[target captureViewHierarchy];
}

- (IBAction)_presentIncompatibleProfilingTarget:(NSButton*)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = _targets[row];
	
	auto alert = [NSAlert new];
	
	alert.alertStyle = NSAlertStyleCritical;
	alert.messageText = NSLocalizedString(@"Incompatible Profiler Framework", @"");
	
	auto informativeText = [NSMutableString new];
	[informativeText appendString:NSLocalizedString(@"The profiler version of this app is incompatible with the current version of Detox Instruments.", @"")];
	[informativeText appendFormat:@"\n\n"];
	[informativeText appendFormat:@"%@: %@\n", NSLocalizedString(@"Profiler framework version", @""), target.deviceInfo[@"profilerVersion"]];
	[informativeText appendFormat:@"%@: %@.%@", NSLocalizedString(@"Detox Instruments version", @""), [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
	
	alert.informativeText = informativeText;
	
	[alert addButtonWithTitle:NSLocalizedString(@"Check for Updates", nil)];
	[alert.buttons.firstObject setAction:@selector(_dismissWarningCheckForUpdates:)];
	
	[alert layout];
	
	// Instantiate a new NSPopover with a view controller that manages this alert's view
	NSViewController *controller = [[NSViewController alloc] init];
	controller.view = alert.window.contentView;
	
	_warningPopover = [NSPopover new];
	_warningPopover.contentViewController = controller;
	_warningPopover.behavior = NSPopoverBehaviorTransient;
	_warningPopover.delegate = self;
	
	// Open the alert within the popover and mark it as the currently shown one.
	[_warningPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMaxYEdge];
}

- (IBAction)_dismissWarningCheckForUpdates:(id)sender
{
	[NSApp sendAction:NSSelectorFromString(@"checkForUpdates:") to:nil from:nil];
	
	[_warningPopover close];
}

- (IBAction)_doubleClicked:(id)sender
{
	if(_outlineView.clickedRow == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = _targets[_outlineView.clickedRow];
	
	if(target.state != DTXRemoteTargetStateDeviceInfoLoaded)
	{
		return;
	}
	
	if(target.isCompatibleWithInstruments == NO)
	{
		return;
	}
	
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration profilingConfigurationForRemoteProfilingFromDefaults];
	
	[self.delegate recordingTargetPicker:self didSelectRemoteProfilingTarget:_targets[_outlineView.selectedRow] profilingConfiguration:config];
}

- (void)dealloc
{
	for(DTXProfilingTargetManagementWindowController* targetManager in _targetManagementControllers.objectEnumerator)
	{
		[targetManager dismissPreferencesWindow];
	}
	
	[_targetManagementControllers removeAllObjects];
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	service.delegate = self;
	
	DTXRemoteTarget* target = [DTXRemoteTarget new];
	[self _addTarget:target forService:service];
	
	[service resolveWithTimeout:10];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:service];
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
	DTXRemoteTarget* target = item;
	
	DTXRemoteTargetCellView* cellView = [outlineView makeViewWithIdentifier:@"DTXRemoteTargetCellView" owner:nil];
	
	[cellView updateWithTarget:target];
	
	return cellView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[self _validateSelectButton];
}

- (void)_validateSelectButton
{
	BOOL hasSelection = _outlineView.selectedRowIndexes.count > 0;
	BOOL hasCompatibleVersion = NO;
	
	if(hasSelection)
	{
		DTXRemoteTarget* target = [_outlineController.outlineView itemAtRow:_outlineView.selectedRow];
		hasCompatibleVersion = target.isCompatibleWithInstruments;
	}
	
	_outlineController.selectButton.enabled = hasSelection && hasCompatibleVersion;
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:sender];
	target.delegate = self;
	
	[target _connectWithHostName:sender.hostName port:sender.port workQueue:_workQueue];
	
	[target loadDeviceInfo];
	
	[self _updateTarget:target];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	[self _removeTargetForService:sender];
}

#pragma mark DTXRemoteTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteTarget*)target
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self _removeTargetForService:[_targetToServiceMapping objectForKey:target]];
	});
}

- (void)profilingTargetDidLoadDeviceInfo:(DTXRemoteTarget *)target
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _updateTarget:target];
	});
}

- (void)profilingTargetDidLoadScreenSnapshot:(DTXRemoteTarget*)target
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _updateTarget:target];
	});
}

- (void)profilingTargetdidLoadContainerContents:(DTXRemoteTarget *)target
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[_targetManagementControllers objectForKey:target] noteProfilingTargetDidLoadContainerContents];
	});
}

- (void)profilingTarget:(DTXRemoteTarget *)target didDownloadContainerContents:(NSData *)containerContents wasZipped:(BOOL)wasZipped
{
	if(containerContents.length == 0)
	{
		//TODO: Display error
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[_targetManagementControllers objectForKey:target] showSaveDialogForSavingData:containerContents dataWasZipped:wasZipped];
	});
}

- (void)profilingTarget:(DTXRemoteTarget *)target didLoadUserDefaults:(NSDictionary *)userDefaults
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[_targetManagementControllers objectForKey:target] noteProfilingTargetDidLoadUserDefaults];
	});
}

- (void)profilingTarget:(DTXRemoteTarget *)target didLoadCookies:(NSArray<NSDictionary<NSString *,id> *> *)cookies
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[_targetManagementControllers objectForKey:target] noteProfilingTargetDidLoadCookies];
	});
}

- (void)profilingTarget:(DTXRemoteTarget *)target didLoadPasteboardContents:(NSArray<NSDictionary<NSString *,id> *> *)pasteboardContents
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[_targetManagementControllers objectForKey:target] noteProfilingTargetDidLoadPasteboardContents];
	});
}

#pragma mark NSPopoverDelegate

- (void)popoverWillClose:(NSNotification *)notification
{
	_warningPopover = nil;
}

@end
