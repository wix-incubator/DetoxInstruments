//
//  DTXDeviceSnapshotManager.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/17/18.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface DTXDeviceSnapshotManager : NSObject

- (instancetype)initWithDeviceImageView:(NSImageView*)deviceImageView snapshotImageView:(NSImageView*)snapshotImageView;

- (void)clearDevice;
- (void)setMachineName:(NSString*)machineName resolution:(NSString*)resolution enclosureColor:(NSString*)enclosureColor;
- (void)setDeviceScreenSnapshot:(NSImage*)deviceScreenSnapshot;

@end

NS_ASSUME_NONNULL_END
