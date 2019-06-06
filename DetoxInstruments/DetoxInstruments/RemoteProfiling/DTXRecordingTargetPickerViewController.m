//
//  DTXRecordingTargetPickerViewController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 20/07/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteTarget-Private.h"
#import "DTXRemoteTargetCellView.h"
#import "DTXProfilingBasics.h"
#import "DTXProfilingConfiguration+RemoteProfilingSupport.h"
#import "_DTXTargetsOutlineViewContoller.h"
#import "_DTXProfilingConfigurationViewController.h"
#import "DTXProfilingTargetManagementWindowController.h"
#import <arpa/inet.h>

static NSString* const DTXRecordingTargetPickerLocalOnlyKey = @"DTXRecordingTargetPickerLocalOnlyKey";

@import QuartzCore;

@interface DTXRecordingTargetPickerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, DTXRemoteTargetDelegate, NSPopoverDelegate, NSTouchBarDelegate>
{
	IBOutlet NSView* _containerView;
	IBOutlet NSLayoutConstraint* _containerConstraint;
	
	IBOutlet NSStackView* _actionButtonsStackView;
	IBOutlet NSStackView* _moreButtonsStackView;
	
	_DTXTargetsOutlineViewContoller* _outlineController;
	NSOutlineView* _outlineView;
	
	_DTXProfilingConfigurationViewController* _profilingConfigurationController;
	NSViewController<_DTXActionButtonProvider>* _activeController;
	
	IBOutlet NSButton* _cancelButton;
	
	NSNetServiceBrowser* _browser;
	
	NSMutableArray<DTXRemoteTarget*>* _resolvingTargets;
	NSMutableArray<DTXRemoteTarget*>* _localTargets;
	NSMutableArray<DTXRemoteTarget*>* _remoteTargets;
	
	NSMapTable<NSNetService*, DTXRemoteTarget*>* _serviceToTargetMapping;
	NSMapTable<DTXRemoteTarget*, NSNetService*>* _targetToServiceMapping;
	
	dispatch_queue_t _workQueue;
	
	NSMapTable<DTXRemoteTarget*, DTXProfilingTargetManagementWindowController*>* _targetManagementControllers;
	
	NSPopover* _warningPopover;
}

@property (nonatomic) BOOL hideRemoteTargets;

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
	
	_resolvingTargets = [NSMutableArray new];
	_localTargets = [NSMutableArray new];
	_remoteTargets = [NSMutableArray new];
	
	_serviceToTargetMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	_targetToServiceMapping = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	
	self.view.wantsLayer = YES;
	self.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	_containerView.wantsLayer = YES;
	_containerView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
	_workQueue = dispatch_queue_create("com.wix.DTXRemoteProfiler", qosAttribute);
	
	_browser = [NSNetServiceBrowser new];
//	_browser.includesPeerToPeer = YES;
	_browser.delegate = self;
	
	_targetManagementControllers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
	
	self.hideRemoteTargets = [NSUserDefaults.standardUserDefaults boolForKey:DTXRecordingTargetPickerLocalOnlyKey];
	[_outlineController.localOnlyButton bind:NSValueBinding toObject:self withKeyPath:@"hideRemoteTargets" options:nil];
}

- (void)setHideRemoteTargets:(BOOL)hideRemoteTargets
{
	_hideRemoteTargets = hideRemoteTargets;
	
	[NSUserDefaults.standardUserDefaults setBool:hideRemoteTargets forKey:DTXRecordingTargetPickerLocalOnlyKey];
	
	[_outlineView reloadData];
	
	[self _validateSelectButton];
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
	
	DTXRemoteTarget* target = [_outlineView itemAtRow:_outlineView.selectedRow];
	
	if(target.state != DTXRemoteTargetStateDeviceInfoLoaded)
	{
		return;
	}
	
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration profilingConfigurationForRemoteProfilingFromDefaults];
	
	[self.delegate recordingTargetPicker:self didSelectRemoteProfilingTarget:target profilingConfiguration:config];
}

- (IBAction)cancel:(id)sender
{
	if([_activeController conformsToProtocol:@protocol(NSUserInterfaceValidations)])
	{
		BOOL shouldGoBack = [(id<NSUserInterfaceValidations>)_activeController validateUserInterfaceItem:sender];
		if(shouldGoBack == NO)
		{
			NSBeep();
			return;
		}
	}
	
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
		[_actionButtonsStackView insertArrangedSubview:button atIndex:0];
		if(button.bezelStyle == NSBezelStyleRounded && [button.title isEqualToString:@"Refresh"] == NO)
		{
			[NSLayoutConstraint activateConstraints:@[[button.widthAnchor constraintEqualToAnchor:_cancelButton.widthAnchor]]];
		}
	}];
	
	if([provider respondsToSelector:@selector(moreButtons)])
	{
		[provider.moreButtons enumerateObjectsUsingBlock:^(NSButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
			button.translatesAutoresizingMaskIntoConstraints = NO;
			[_moreButtonsStackView addArrangedSubview:button];
			if(button.bezelStyle == NSBezelStyleRounded && [button.title isEqualToString:@"Refresh"] == NO)
			{
				[NSLayoutConstraint activateConstraints:@[[button.widthAnchor constraintEqualToAnchor:_cancelButton.widthAnchor]]];
			}
		}];
	}
	
	self.touchBar = [self makeTouchBar];
}

- (void)_removeActionButtonsWithProvider:(id<_DTXActionButtonProvider>)provider
{
	[provider.actionButtons enumerateObjectsUsingBlock:^(NSButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
		[_actionButtonsStackView removeView:button];
	}];
	
	if([provider respondsToSelector:@selector(moreButtons)])
	{
		[provider.moreButtons enumerateObjectsUsingBlock:^(NSButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
			[_moreButtonsStackView removeView:button];
		}];
	}
	
	self.touchBar = [self makeTouchBar];
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
	
	transitionOptions |= NSViewControllerTransitionCrossfade;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.3;
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

		_containerConstraint.animator.constant = controller.view.fittingSize.height;
		
		[NSAnimationContext beginGrouping];
		
		NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
		
		[self _removeActionButtonsWithProvider:_activeController];
		[self _setupActionButtonsWithProvider:controller];
		
		[NSAnimationContext endGrouping];
		
		[self transitionFromViewController:_activeController toViewController:controller options:transitionOptions completionHandler:nil];
		
	} completionHandler:nil];
	
	_activeController = controller;
	
	[self _validateSelectButton];
}

- (void)_addLocalTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service announceToOutlineView:(BOOL)announce
{
	[self _addTarget:target forService:service];
	
	[_localTargets addObject:target];
	
	if(announce == YES)
	{
		NSIndexSet* itemIndexSet = [NSIndexSet indexSetWithIndex:_localTargets.count - 1];
		[_outlineView insertItemsAtIndexes:itemIndexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
		if(itemIndexSet.firstIndex == 0)
		{
			[_outlineView selectRowIndexes:itemIndexSet byExtendingSelection:NO];
		}
	}
}

- (void)_addRemoteTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service announceToOutlineView:(BOOL)announce
{
	[self _addTarget:target forService:service];
	
	[_remoteTargets addObject:target];
	
	if(announce == YES && _hideRemoteTargets == NO)
	{
		NSIndexSet* itemIndexSet = [NSIndexSet indexSetWithIndex:_localTargets.count + _remoteTargets.count - 1];
		[_outlineView insertItemsAtIndexes:itemIndexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
		if(itemIndexSet.firstIndex == 0)
		{
			[_outlineView selectRowIndexes:itemIndexSet byExtendingSelection:NO];
		}
	}
}

- (void)_addResolvingTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service announceToOutlineView:(BOOL)announce
{
	[self _addTarget:target forService:service];
	
	[_resolvingTargets addObject:target];
	
	NSUInteger offset = _localTargets.count;
	if(_hideRemoteTargets == NO)
	{
		offset += _remoteTargets.count;
	}
	
	if(announce == YES)
	{
		NSIndexSet* itemIndexSet = [NSIndexSet indexSetWithIndex:offset + _resolvingTargets.count - 1];
		[_outlineView insertItemsAtIndexes:itemIndexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
		if(itemIndexSet.firstIndex == 0)
		{
			[_outlineView selectRowIndexes:itemIndexSet byExtendingSelection:NO];
		}
	}
}

- (void)_addTarget:(DTXRemoteTarget*)target forService:(NSNetService*)service
{
	[_serviceToTargetMapping setObject:target forKey:service];
	[_targetToServiceMapping setObject:service forKey:target];
}

- (NSUInteger)_indexOfTarget:(DTXRemoteTarget*)target
{
	NSUInteger rv = [_localTargets indexOfObject:target];
	if(rv == NSNotFound)
	{
		NSUInteger other;
		NSUInteger offset = _localTargets.count;
		
		if(_hideRemoteTargets == NO)
		{
			other = [_remoteTargets indexOfObject:target];
			if(other != NSNotFound)
			{
				rv = _localTargets.count + other;
				return rv;
			}
			
			offset += _remoteTargets.count;
		}
		
		other = [_resolvingTargets indexOfObject:target];
		if(other != NSNotFound)
		{
			rv = offset + other;
		}
	}
	
	return rv;
}

- (void)_removeTargetForService:(NSNetService*)service announceToOutlineView:(BOOL)announce
{
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target == nil)
	{
		return;
	}
	
	NSUInteger index = [self _indexOfTarget:target];
	if(index == NSNotFound)
	{
		[_outlineView reloadData];
		
		return;
	}
	
	[[_targetManagementControllers objectForKey:target] dismissPreferencesWindow];
	[_targetManagementControllers removeObjectForKey:target];
	
	[_localTargets removeObject:target];
	[_remoteTargets removeObject:target];
	[_resolvingTargets removeObject:target];
	[_serviceToTargetMapping removeObjectForKey:service];
	[_targetToServiceMapping removeObjectForKey:target];
	
	if(announce == YES)
	{
		[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectFade];
		
		[self _validateSelectButton];
	}
}

- (void)_updateTarget:(DTXRemoteTarget*)target
{
	[_outlineView reloadItem:target];
	
	[self _validateSelectButton];
}

- (IBAction)_manageProfilingTarget:(NSButton*)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		return;
	}
	
	id target = [_outlineView itemAtRow:row];
	
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
	
	DTXRemoteTarget* target = [_outlineView itemAtRow:row];
	
	[target captureViewHierarchy];
}

- (IBAction)_presentIncompatibleProfilingTarget:(NSButton*)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = [_outlineView itemAtRow:row];
	
	auto alert = [NSAlert new];
	
	alert.alertStyle = NSAlertStyleCritical;
	alert.messageText = NSLocalizedString(@"Incompatible Profiler Framework", @"");
	
	auto informativeText = [NSMutableString new];
	[informativeText appendString:NSLocalizedString(@"The profiler version of this app is incompatible with the current version of Detox Instruments.", @"")];
	[informativeText appendFormat:@"\n\n"];
	[informativeText appendFormat:@"%@: %@\n", NSLocalizedString(@"Profiler framework version", @""), target.deviceInfo[@"profilerVersion"]];
	[informativeText appendFormat:@"%@: %@", NSLocalizedString(@"Detox Instruments version", @""), DTXApp.applicationVersion];
	
	alert.informativeText = informativeText;
	
	if([DTXApp.applicationVersion compare:target.deviceInfo[@"profilerVersion"] options:NSNumericSearch] == NSOrderedAscending)
	{
		//Only show the button in case Instruments is older than profiler.
		[alert addButtonWithTitle:NSLocalizedString(@"Check for Updates", nil)];
		[alert.buttons.firstObject setAction:@selector(_dismissWarningCheckForUpdates:)];
	}
	else
	{
		[alert addButtonWithTitle:NSLocalizedString(@"Dismiss", nil)];
		[alert.buttons.firstObject setAction:@selector(_dismissWarning:)];
	}
	
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

- (IBAction)_dismissWarning:(id)sender
{
	[_warningPopover close];
}

- (IBAction)_doubleClicked:(id)sender
{
	if(_outlineView.clickedRow == -1)
	{
		return;
	}
	
	DTXRemoteTarget* target = [_outlineView itemAtRow:_outlineView.clickedRow];
	
	if(target.state != DTXRemoteTargetStateDeviceInfoLoaded)
	{
		return;
	}
	
	if(target.isCompatibleWithInstruments == NO)
	{
		return;
	}
	
	DTXProfilingConfiguration* config = [DTXProfilingConfiguration profilingConfigurationForRemoteProfilingFromDefaults];
	
	[self.delegate recordingTargetPicker:self didSelectRemoteProfilingTarget:target profilingConfiguration:config];
}

- (void)dealloc
{
	for(DTXProfilingTargetManagementWindowController* targetManager in _targetManagementControllers.objectEnumerator)
	{
		[targetManager dismissPreferencesWindow];
	}
	
	[_targetManagementControllers removeAllObjects];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
{
	if(item != nil)
	{
		return 0;
	}
	
	NSUInteger count = _localTargets.count + _resolvingTargets.count;
	if(_hideRemoteTargets == NO)
	{
		count += _remoteTargets.count;
	}
	
	return count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	if(index < _localTargets.count)
	{
		return _localTargets[index];
	}
	
	index -= _localTargets.count;
	
	if(_hideRemoteTargets == NO)
	{
		if(index < _remoteTargets.count)
		{
			return _remoteTargets[index];
		}
		
		index -= _remoteTargets.count;
	}
	
	return _resolvingTargets[index];
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
	BOOL hasLoaded = NO;
	BOOL hasCompatibleVersion = NO;
	
	if(hasSelection)
	{
		DTXRemoteTarget* target = [_outlineController.outlineView itemAtRow:_outlineView.selectedRow];
		
		hasLoaded = target.state >= DTXRemoteTargetStateDeviceInfoLoaded;
		hasCompatibleVersion = target.isCompatibleWithInstruments;
	}
	
	_outlineController.selectButton.enabled = hasSelection && hasLoaded && hasCompatibleVersion;
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	service.delegate = self;
	
	DTXRemoteTarget* target = [DTXRemoteTarget new];
	target.delegate = self;
	[self _addResolvingTarget:target forService:service announceToOutlineView:YES];
	
	[service resolveWithTimeout:2];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:service];
	if(target.state < DTXRemoteTargetStateResolved)
	{
		[self _removeTargetForService:service announceToOutlineView:YES];
	}
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	DTXRemoteTarget* target = [_serviceToTargetMapping objectForKey:sender];
	
	NSArray* currentAddresses = NSHost.currentHost.addresses;
	
	__block BOOL isLocalHost = NO;
	[sender.addresses enumerateObjectsUsingBlock:^(NSData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
	{
		struct sockaddr * socketAddress = (struct sockaddr *)obj.bytes;
		if(socketAddress != nil)
		{
			char buffer[256];
			if(inet_ntop(socketAddress->sa_family, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, 255))
			{
				NSString* address = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
				
				if([currentAddresses containsObject:address])
				{
					isLocalHost = YES;
					*stop = YES;
					return;
				}
			}
		}
	}];
	
	[_outlineView beginUpdates];
	[self _removeTargetForService:sender announceToOutlineView:YES];
	if(isLocalHost == YES)
	{
		[self _addLocalTarget:target forService:sender announceToOutlineView:YES];
	}
	else
	{
		[self _addRemoteTarget:target forService:sender announceToOutlineView:YES];
	}
	[_outlineView endUpdates];
	
	[target _connectWithHostName:sender.hostName port:sender.port workQueue:_workQueue];
	
	[target loadDeviceInfo];
	
	[self _updateTarget:target];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *, NSNumber *> *)errorDict
{
	[self _removeTargetForService:sender announceToOutlineView:YES];
}

#pragma mark DTXRemoteTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteTarget*)target
{
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self _removeTargetForService:[_targetToServiceMapping objectForKey:target] announceToOutlineView:YES];
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

#pragma mark NSTouchBarProvider

- (NSCustomTouchBarItem*)_touchBarButtonItemWithButton:(NSButton*)obj identifier:(NSString*)identifier
{
	NSButton *button = [NSButton buttonWithTitle:obj.title target:obj.target action:obj.action];
	button.bezelStyle = obj.bezelStyle;
	if(button.bezelStyle == NSBezelStyleHelpButton)
	{
		button.bezelStyle = NSBezelStyleRounded;
		button.title = NSLocalizedString(@"Help", @"");
	}
	button.keyEquivalent = obj.keyEquivalent;
	NSCustomTouchBarItem *buttonBarItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
	buttonBarItem.view = button;
	
	return buttonBarItem;
}

- (NSTouchBar *)makeTouchBar
{
	NSMutableArray<NSString*>* buttonIdentifiers = [NSMutableArray new];
	NSMutableSet<NSTouchBarItem*>* buttonsSet = [NSMutableSet new];
	
	[buttonIdentifiers addObject:NSTouchBarItemIdentifierFlexibleSpace];
	
	[_moreButtonsStackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* identifier = [NSString stringWithFormat:@"MoreButton%@", @(idx)];
		
		NSCustomTouchBarItem *buttonBarItem = [self _touchBarButtonItemWithButton:obj identifier:identifier];
		
		[buttonIdentifiers addObject:identifier];
		[buttonsSet addObject:buttonBarItem];
	}];
	
	[buttonIdentifiers addObject:NSTouchBarItemIdentifierFixedSpaceLarge];
	
	[_actionButtonsStackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof NSButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSString* identifier = [NSString stringWithFormat:@"Button%@", @(idx)];
	
		NSCustomTouchBarItem *buttonBarItem = [self _touchBarButtonItemWithButton:obj identifier:identifier];
		
		[buttonIdentifiers addObject:identifier];
		[buttonsSet addObject:buttonBarItem];
	}];
	
	[buttonIdentifiers addObject:NSTouchBarItemIdentifierFlexibleSpace];
	
	NSGroupTouchBarItem* group = [NSGroupTouchBarItem alertStyleGroupItemWithIdentifier:@"DTXRecordingTargetPickerButtons"];
	group.groupTouchBar.defaultItemIdentifiers = buttonIdentifiers;
	group.groupTouchBar.templateItems = buttonsSet;
	
	NSTouchBar* bar = [NSTouchBar new];
	bar.defaultItemIdentifiers = @[@"DTXRecordingTargetPickerButtons"];
	bar.templateItems = [NSSet setWithObject:group];
	
	return bar;
}

#pragma mark NSTouchBarDelegate

//- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
//{
//
//}

@end
