//
//  DTXDeviceSnapshotManager.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/17/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXDeviceSnapshotManager.h"
#import "NSImage+UIAdditions.h"
#import "NSURL+UIAdditions.h"
@import AVFoundation;
@import CommonCrypto.CommonDigest;
@import QuickLook;

static NSDictionary* _deviceMapping;

@implementation DTXDeviceSnapshotManager
{
	NSData* _currentHash;
	
	NSImageView* _deviceImageView;
	NSImageView* _snapshotImageView;
	NSSize _currentDeviceScreenResolution;
	
	NSClickGestureRecognizer* _clickGestureRecognizer;
}

static NSData* __DTXSHADataOfString(NSString* string)
{
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
	
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

+ (void)load
{
	_deviceMapping = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:self] URLForResource:@"DTXDeviceSnapshotDevices" withExtension:@"plist"]];
}

- (instancetype)initWithDeviceImageView:(NSImageView*)deviceImageView snapshotImageView:(NSImageView*)snapshotImageView
{
	self = [super init];
	
	if(self)
	{
		_deviceImageView = deviceImageView;
		_snapshotImageView = snapshotImageView;
		
		_snapshotImageView.hidden = YES;
		
		_clickGestureRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(_clicked)];
		[_deviceImageView addGestureRecognizer:_clickGestureRecognizer];
	}
	
	return self;
}

- (void)_clicked
{
	NSImage* snapshotImage = [_snapshotImageView.image copy];
	snapshotImage.size = _currentDeviceScreenResolution;
	
	NSBitmapImageRep* bmp = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:_currentDeviceScreenResolution.width pixelsHigh:_currentDeviceScreenResolution.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:_currentDeviceScreenResolution.width * 8 bitsPerPixel:32];
	NSGraphicsContext* ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:bmp];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:ctx];
	[snapshotImage drawInRect:(NSRect){0, 0, _currentDeviceScreenResolution}];
	[ctx flushGraphics];
	[NSGraphicsContext restoreGraphicsState];
	
	NSURL *temporaryURL = [NSURL.temporaryDirectoryURL URLByAppendingPathComponent:@"Screenshot.png"];
	
	[[bmp representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToURL:temporaryURL atomically:YES];
	
	[NSWorkspace.sharedWorkspace openURL:temporaryURL];
}

- (void)clearDevice
{
	_currentHash = nil;
	_deviceImageView.hidden = YES;
	_snapshotImageView.hidden = YES;
}

- (void)setMachineName:(NSString*)machineName resolution:(NSString*)resolution enclosureColor:(NSString*)enclosureColor
{
	NSString* all = [NSString stringWithFormat:@"%@%@%@", machineName, resolution, enclosureColor];
	NSData* sha = __DTXSHADataOfString(all);
	
	if([sha isEqualToData:_currentHash])
	{
		return;
	}
	
	_currentHash = sha;
	
	_deviceImageView.hidden = NO;
	
	NSDictionary* mapping = _deviceMapping[@"mappings"][machineName];
	if(mapping == nil)
	{
		if([machineName hasPrefix:@"iPad"])
		{
			mapping = _deviceMapping[@"mappings"][@"iPad"];
		}
		else
		{
			mapping = _deviceMapping[@"mappings"][@"iPhone"];
		}
	}
	
	NSString* familyName = mapping[@"family"];
	NSString* modelName = mapping[@"model"];
	
	NSDictionary* bestGuess = mapping[@"bestGuess"];
	if(bestGuess && bestGuess[resolution])
	{
		modelName = bestGuess[resolution];
	}
	
	NSDictionary* family = _deviceMapping[@"families"][familyName];
	NSString* familyBaseName = family[@"baseName"];
	NSString* familyImageBaseName = family[@"baseImageName"];

	NSDictionary* device = family[@"models"][modelName];
	
	NSString* deviceNameSuffix = device[@"nameSuffix"];
	NSString* deviceImageNameSuffix = device[@"imageNameSuffix"];
	
	NSMutableString* deviceName = [familyBaseName mutableCopy];
	if(deviceNameSuffix.length > 0)
	{
		[deviceName appendFormat:@" %@", deviceNameSuffix];
	}
	
	NSMutableString* deviceImageName = [familyImageBaseName mutableCopy];
	if(deviceImageNameSuffix.length > 0)
	{
		[deviceImageName appendFormat:@"_%@", deviceImageNameSuffix];
	}
	
	NSString* color = device[@"colorSuffixes"][enclosureColor];
	if(color.length > 0)
	{
		[deviceImageName appendFormat:@"_%@", color];
	}
	
	NSImage* deviceImage = [NSImage imageNamed:deviceImageName];
	
	_currentDeviceScreenResolution = NSSizeFromString(device[@"resolution"]);
	
	_deviceImageView.image = deviceImage;
	
	[self setDeviceScreenSnapshot:[NSImage imageWithColor:NSColor.whiteColor size:_currentDeviceScreenResolution]];
}

- (void)setDeviceScreenSnapshot:(NSImage*)deviceScreenSnapshot
{
	_snapshotImageView.hidden = NO;
	
	NSImage* displayImage = [deviceScreenSnapshot copy];
	CGRect rect = AVMakeRectWithAspectRatioInsideRect(_currentDeviceScreenResolution, CGRectMake(0, 0, 70 * _currentDeviceScreenResolution.width / _deviceImageView.image.size.width, 70 * _currentDeviceScreenResolution.height / _deviceImageView.image.size.height));
	displayImage.size = rect.size;
	
	_snapshotImageView.image = displayImage;
}

@end
