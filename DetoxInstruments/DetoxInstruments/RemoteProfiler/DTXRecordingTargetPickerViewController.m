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

@import QuartzCore;

@interface DTXRecordingTargetPickerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, DTXRemoteProfilingTargetDelegate>
{
	IBOutlet NSView* _containerView;
	
	_DTXTargetsOutlineViewContoller* _outlineController;
	NSOutlineView* _outlineView;
	
	_DTXProfilingConfigurationViewController* _profilingConfigurationController;
	
	IBOutlet NSButton* _selectButton;
	IBOutlet NSButton* _cancelButton;
	IBOutlet NSButton* _optionsButton;
	
	NSNetServiceBrowser* _browser;
	NSMutableArray<DTXRemoteProfilingTarget*>* _targets;
	NSMapTable<NSNetService*, DTXRemoteProfilingTarget*>* _serviceToTargetMapping;
	NSMapTable<DTXRemoteProfilingTarget*, NSNetService*>* _targetToServiceMapping;
	
	dispatch_queue_t _workQueue;
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
	_outlineController.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	_outlineView = _outlineController.outlineView;
	_outlineView.dataSource = self;
	_outlineView.delegate = self;
	_outlineView.doubleAction = @selector(_doubleClicked:);
	
	_profilingConfigurationController = [self.storyboard instantiateControllerWithIdentifier:@"_DTXProfilingConfigurationViewController"];
	[self addChildViewController:_profilingConfigurationController];
	_profilingConfigurationController.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	_outlineController.view.translatesAutoresizingMaskIntoConstraints = NO;
	_profilingConfigurationController.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	[_containerView addSubview:_outlineController.view];
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

- (IBAction)selectRecording:(id)sender
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
	if(_profilingConfigurationController.view.superview != nil)
	{
		[self _transitionToDevice];
		
		return;
	}
	
	[self.delegate recordingTargetPickerDidCancel:self];
}

- (IBAction)options:(id)sender
{
	[self _transitionToOptions];
}

- (void)_transitionToOptions
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.3;
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		[self transitionFromViewController:_outlineController toViewController:_profilingConfigurationController options:NSViewControllerTransitionSlideForward completionHandler:nil];
	} completionHandler:nil];
	
	_selectButton.enabled = NO;
	_selectButton.hidden = YES;
	_optionsButton.hidden = YES;
	_cancelButton.title = NSLocalizedString(@"Back", @"");
}

- (void)_transitionToDevice
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		context.duration = 0.3;
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		[self transitionFromViewController:_profilingConfigurationController toViewController:_outlineController options:NSViewControllerTransitionSlideBackward completionHandler:nil];
	} completionHandler:nil];
	
	_selectButton.hidden = NO;
	_optionsButton.hidden = NO;
	_cancelButton.title = NSLocalizedString(@"Cancel", @"");
	[self _validateSelectButton];
}

- (void)_addTarget:(DTXRemoteProfilingTarget*)target forService:(NSNetService*)service
{
	[_serviceToTargetMapping setObject:target forKey:service];
	[_targetToServiceMapping setObject:service forKey:target];
	[_targets addObject:target];
	
	NSIndexSet* itemIndexSet = [NSIndexSet indexSetWithIndex:_targets.count - 1];
	[_outlineView insertItemsAtIndexes:itemIndexSet inParent:nil withAnimation:NSTableViewAnimationEffectNone];
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
	
	[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:nil withAnimation:NSTableViewAnimationEffectFade];
}

- (void)_updateTarget:(DTXRemoteProfilingTarget*)target
{
	[_outlineView reloadItem:target];
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
	_selectButton.enabled = _outlineView.selectedRowIndexes.count > 0;
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

@end
