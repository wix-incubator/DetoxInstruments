//
//  DTXFilterAccessoryController.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 8/30/20.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXFilterAccessoryController.h"

@interface DTXFilterAccessoryController ()

@property (nonatomic) BOOL errorsOnly;
@property (nonatomic) BOOL appOnly;
@property (nonatomic) BOOL excludeApple;

@end

@implementation DTXFilterAccessoryController

+ (void)load
{
	[NSUserDefaults.standardUserDefaults registerDefaults:@{
		@"DTXLiveLog_errorsOnly": @NO,
		@"DTXLiveLog_appOnly": @YES,
		@"DTXLiveLog_excludeApple": @YES,
	}];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.errorsOnly = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXLiveLog_errorsOnly"];
	self.appOnly = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXLiveLog_appOnly"];
	self.excludeApple = [NSUserDefaults.standardUserDefaults boolForKey:@"DTXLiveLog_excludeApple"];
	
	[self.delegate allMessages:!self.errorsOnly];
	[self.delegate allProcesses:!self.appOnly];
	[self.delegate includeApple:!self.excludeApple];
}

- (void)setErrorsOnly:(BOOL)errorsOnly
{
	[self willChangeValueForKey:@"errorsOnly"];
	
	_errorsOnly = errorsOnly;
	[NSUserDefaults.standardUserDefaults setBool:self.errorsOnly forKey:@"DTXLiveLog_errorsOnly"];
	
	[self.delegate allMessages:!errorsOnly];
	
	[self didChangeValueForKey:@"errorsOnly"];
}

- (void)setAppOnly:(BOOL)appOnly
{
	[self willChangeValueForKey:@"appOnly"];
	
	_appOnly = appOnly;
	[NSUserDefaults.standardUserDefaults setBool:self.appOnly forKey:@"DTXLiveLog_appOnly"];
	
	[self.delegate allProcesses:!appOnly];
	
	[self didChangeValueForKey:@"appOnly"];
}

- (void)setExcludeApple:(BOOL)excludeApple
{
	[self willChangeValueForKey:@"excludeApple"];
	
	_excludeApple = excludeApple;
	[NSUserDefaults.standardUserDefaults setBool:self.excludeApple forKey:@"DTXLiveLog_excludeApple"];
	
	[self.delegate includeApple:!excludeApple];
	
	[self didChangeValueForKey:@"excludeApple"];
}

@end
