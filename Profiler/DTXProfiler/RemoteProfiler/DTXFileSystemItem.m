//
//  DTXFileSystemItem.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 3/29/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXFileSystemItem.h"
#import "DTXZipper.h"

@implementation DTXFileSystemItem

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	self = [super init];
	
	if(self)
	{
		NSArray<NSURLResourceKey>* propKeys = @[NSURLIsDirectoryKey, NSURLNameKey, NSURLTotalFileSizeKey];
		NSDictionary<NSURLResourceKey, id>* properties = [fileURL resourceValuesForKeys:propKeys error:NULL];
		
		_isDirectory = [properties[NSURLIsDirectoryKey] boolValue];
		self.name = properties[NSURLNameKey];
		self.size = properties[NSURLTotalFileSizeKey];
		self.URL = fileURL;
		
		if([properties[NSURLIsDirectoryKey] boolValue])
		{
			NSArray<NSURL*>* childURLs = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.URL includingPropertiesForKeys:propKeys options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles error:NULL] sortedArrayUsingComparator:^NSComparisonResult(NSURL* _Nonnull obj1, NSURL* _Nonnull obj2) {
				
				NSString* val1;
				NSString* val2;
				
				[obj1 getResourceValue:&val1 forKey:NSURLNameKey error:NULL];
				[obj2 getResourceValue:&val2 forKey:NSURLNameKey error:NULL];
				
				return [val1 compare:val2 options:(NSCaseInsensitiveSearch)];
			}];
			
			NSMutableArray* children = [NSMutableArray new];
			
			__block unsigned long long size = 0;
			
			[childURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
				DTXFileSystemItem* child = [[DTXFileSystemItem alloc] initWithFileURL:obj];
				size += child.size.unsignedLongLongValue;
				[children addObject:child];
			}];
			
			self.children = children;
			self.size = @(size);
		}
		else
		{
			self.children = nil;
		}
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if(self)
	{
		_isDirectory = [aDecoder decodeBoolForKey:@"isDirectory"];
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.size = [aDecoder decodeObjectForKey:@"size"];
		self.URL = [aDecoder decodeObjectForKey:@"URL"];
		self.children = [aDecoder decodeObjectForKey:@"children"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeBool:_isDirectory forKey:@"isDirectory"];
	[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeObject:self.size forKey:@"size"];
	[aCoder encodeObject:self.URL forKey:@"URL"];
	[aCoder encodeObject:self.children forKey:@"children"];
}

- (BOOL)isDirectoryForUI
{
	return _isDirectory && [self.name.pathExtension isEqualToString:@"dtxprof"] == NO;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@: %p [%@] name: %@, size: %@>", self.class, self, self.isDirectory ? @"D" : @"F", self.name, self.size == nil ? @"--" : [NSByteCountFormatter stringFromByteCount:self.size.unsignedIntegerValue countStyle:NSByteCountFormatterCountStyleFile]];
}

- (NSData*)contents
{
	if(_isDirectory == YES)
	{
		return nil;
	}
	
	return [NSData dataWithContentsOfURL:self.URL options:NSDataReadingMappedAlways error:NULL];
}

- (NSData*)zipContents
{
	NSURL* tempFileURL = DTXTempZipURL();
	DTXWriteZipFileWithURL(tempFileURL, self.URL);
	
	NSData* data = [NSData dataWithContentsOfURL:tempFileURL options:NSDataReadingMappedAlways error:NULL];
	
	[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:NULL];
	
	return data;
}

- (NSUInteger)hash
{
	return self.URL.hash;
}

- (BOOL)isEqual:(id)object
{
	DTXFileSystemItem* anotherItem = object;
	
	return [self.URL isEqual:anotherItem.URL] && self.isDirectory == anotherItem.isDirectory;
}

- (BOOL)isEqualToFileSystemItem:(id)object
{
	return [self isEqual:object];
}

- (NSComparisonResult)compare:(DTXFileSystemItem*)object
{
	return [self.URL.path compare:((DTXFileSystemItem*)object).URL.path];
}

@end
