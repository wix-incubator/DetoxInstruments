//
//  DTXAddressInfo.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 07/07/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXAddressInfo.h"
#include <dlfcn.h>
#include <cxxabi.h>

@implementation DTXAddressInfo
{
	void* _address;
	Dl_info _info;
}

@synthesize image, symbol, offset;

- (instancetype)initWithAddress:(NSUInteger)address
{
	self = [super init];
	
	if(self)
	{
		_address = (void*)address;
		dladdr(_address, &_info);
	}
	
	return self;
}

- (NSString *)image
{
	if(_info.dli_fname != NULL)
	{
		NSString* potentialImage = [NSString stringWithUTF8String:_info.dli_fname];
		
		if([potentialImage containsString:@"/"])
		{
			return potentialImage.lastPathComponent;
		}
	}
	
	return @"???";
}

- (NSString *)symbol
{
	if(_info.dli_sname != NULL)
	{
		int status = -1;
		char* demangled = abi::__cxa_demangle(_info.dli_sname, NULL, NULL, &status);
		NSString* symbol = nil;
		if(demangled)
		{
			symbol = [NSString stringWithUTF8String:demangled];
			free(demangled);
		}
		else
		{
			symbol = [NSString stringWithUTF8String:_info.dli_sname];
		}
		
		return symbol;
	}
	else if(_info.dli_fname != NULL)
	{
		return self.image;
	}
	
	return [NSString stringWithFormat:@"0x%1lx", (unsigned long)_info.dli_saddr];
}

- (NSUInteger)offset
{
	NSString* str = nil;
	if(_info.dli_sname != NULL && (str = [NSString stringWithUTF8String:_info.dli_sname]) != nil)
	{
		return (NSUInteger)_address - (NSUInteger)_info.dli_saddr;
	}
	else if(_info.dli_fname != NULL && (str = [NSString stringWithUTF8String:_info.dli_fname]) != nil)
	{
		return (NSUInteger)_address - (NSUInteger)_info.dli_fbase;
	}
	
	return (NSUInteger)_address - (NSUInteger)_info.dli_saddr;
}

- (NSString*)formattedDescriptionForIndex:(NSUInteger)index;
{
#if __LP64__
	return [NSString stringWithFormat:@"%-4ld%-35s 0x%016llx %@ + %ld", index, self.image.UTF8String, (uint64_t)_address, self.symbol, self.offset];
#else
	return [NSString stringWithFormat:@"%-4d%-35s 0x%08lx %@ + %d", index, self.image.UTF8String, (unsigned long)_address, self.symbol, self.offset];
#endif
}

@end
