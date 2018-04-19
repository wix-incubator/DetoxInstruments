//
//  Created by Frank Gregor on 16.01.15.
//  Copyright (c) 2015 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2014 Frank Gregor, <phranck@cocoanaut.com>
 http://cocoanaut.mit-license.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <AppKit/AppKit.h>
#import "CCNPreferencesWindowControllerProtocol.h"


@interface CCNPreferencesWindowController : NSWindowController

#pragma mark - Preferences Window Behaviour

@property (copy, nonatomic) NSString* titlePrepend;

/** @name Preferences Window Behaviour */

/**
 Boolean property that defines the window level.

 If set to `YES`, the window is on top of all other windows even when you change focus to another app.<br />
 If set to `NO`, the window will only stay on top until you bring another window to front.

 The default is `NO`.
*/
@property (assign, nonatomic) BOOL keepWindowAlwaysOnTop;

/**
 Boolean property that defines whether the title is shown or not.
 
 If set to `YES`, the title is shown and with it the title bar.<br />
 If set to `NO`, title and title bar is hidden.
 
 The default is `YES`.
 */

@property (assign, nonatomic) BOOL titleVisibility;

/**
 This is a forwarder for the used window.

 When `YES`, the titlebar doesn't draw its background, allowing all buttons to show through, and "click through" to happen. In general, this is only useful when `NSFullSizeContentViewWindowMask` is set.
 The default is `NO`.
*/
@property (assign, nonatomic) BOOL titlebarAppearsTransparent;

/**
 This is a forwarder for the toolbar.
 
 Use this API to hide the baseline `NSToolbar` draws between itself and the main window contents.
 The default is `YES`. This method should only be used before the toolbar is attached to its window (`- [NSWindow setToolbar:]`).
 */
@property (assign, nonatomic) BOOL showToolbarSeparator;

/**
 Boolean property that indicates whether the toolbar is visible with a single preferenceViewController or not.

 If set to `YES`, the toolbar is always visible. Otherwise the toolbar will only be shown if there are more than one prefereceViewController.
 
 The default is `YES`.
 */
@property (assign, nonatomic) BOOL showToolbarWithSingleViewController;

/**
 Boolean property that defines the toolbar content presentation.
 
 If set to `YES`, the toolbar content will be presented as a `NSSegmentedControl` without a label and text only segmentItems.<br />
 If set to `NO`, the toolbar content will be presented with standard `NSToolbarItem` items.

 The default is `NO`.
 */
@property (assign, nonatomic) BOOL showToolbarItemsAsSegmentedControl;

/**
 Boolean property that indicates whether the toolbarItems are centered or not.
 
 If set to `YES`, the toolbarItems will be centered otherwise they are left aligned. This property is ignored if `showToolbarItemsAsSegmentedControl` set to `YES`.

 The default is `YES`.
 */
@property (assign, nonatomic) BOOL centerToolbarItems;
/**
 *  Boolean property that indicates whether the toolbar should be customizable.
 *  This property is ignored if `showToolbarItemsAsSegmentedControl` set to `YES`.
 *  The default is `NO`.
 
 */
@property (assign, nonatomic) BOOL shouldAllowToolBarCustomization;

/**
 Boolean property that defines the contentView presentation.
 
 If set to `YES`, the contentView will be embedded in a `NSVisualEffectView` using blending mode `NSVisualEffectBlendingModeBehindWindow`.

 The default is `NO`.
 */
@property (assign, nonatomic) BOOL allowsVibrancy;


#pragma mark - Managing Preference View Controllers
/** @name Managing Preference View Controllers */

/**
 Set the `CCNPreferencesWindowController`'s contentViewControllers.

 @param viewControllers An array of viewControllers. Each viewController must implement the `CCNPreferencesWindowControllerProtocol`.
 
 ```
// init the preferences window controller
CCNPreferencesWindowController *preferences = [CCNPreferencesWindowController new];
preferences.centerToolbarItems = YES;

// setup all preference view controllers
[preferences setPreferencesViewControllers:@[
    [FirstPreferencesViewController new],
    [SecondPreferencesViewController new],
    [ThirdPreferencesViewController new]
]];
 ```
 */
- (void)setPreferencesViewControllers:(NSArray *)viewControllers;


#pragma mark - Show/Hide Preferences Window
/** @name Show/Hide Preferences Window */

/**
 Show the preferences window.
 */
- (void)showPreferencesWindow;

/**
 Hides the preferences window.
 */
- (void)dismissPreferencesWindow;

@end
