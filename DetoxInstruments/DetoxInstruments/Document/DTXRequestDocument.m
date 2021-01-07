//
//  DTXRequestDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 3/13/19.
//  Copyright © 2017-2021 Wix. All rights reserved.
//

#import "DTXRequestDocument.h"
#import "DTXRequestsPlaygroundController.h"

@implementation DTXRequestDocument
{
	DTXNetworkSample* _cachedSample;
	DTXRecordingDocument* _cachedDocument;
	NSURLRequest* _cachedRequest;
}

- (void)loadRequestDetailsFromNetworkSample:(DTXNetworkSample*)networkSample document:(DTXRecordingDocument*)document
{
	if(self.windowControllers.firstObject == nil)
	{
		_cachedSample = networkSample;
		_cachedDocument = document;
		return;
	}
	
	[(DTXRequestsPlaygroundController*)self.windowControllers.firstObject.contentViewController loadRequestDetailsFromNetworkSample:networkSample];
	
	NSFetchRequest* fr = [DTXNetworkSample fetchRequest];
	fr.resultType = NSManagedObjectIDResultType;
	fr.predicate = [NSPredicate predicateWithFormat:@"hidden == NO"];
	fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	NSArray* networks = [document.viewContext executeFetchRequest:fr error:NULL];
	NSUInteger idx = [networks indexOfObject:networkSample.objectID];
	
	NSMutableString* docName = [document.displayName stringByDeletingPathExtension].mutableCopy;
	if(idx != NSNotFound)
	{
		[docName appendFormat:@" %@", @(idx + 1)];
	}
	
	[self updateChangeCount:NSChangeDone];
	self.displayName = docName;
	[self.windowControllers.firstObject synchronizeWindowTitleWithDocumentName];
}

- (void)loadRequestDetailsFromURLRequest:(NSURLRequest*)request
{
	if(self.windowControllers.firstObject == nil)
	{
		_cachedRequest = request;
		return;
	}
	
	[(DTXRequestsPlaygroundController*)self.windowControllers.firstObject.contentViewController loadRequestDetailsFromURLRequest:request];
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
	NSWindowController* wc = [[NSStoryboard storyboardWithName:@"RequestsPlayground" bundle:nil] instantiateInitialController];
	
	[self addWindowController:wc];
	
	if(_cachedSample)
	{
		[self loadRequestDetailsFromNetworkSample:_cachedSample document:_cachedDocument];
		_cachedSample = nil;
		_cachedDocument = nil;
	}
	else if(_cachedRequest)
	{
		[self loadRequestDetailsFromURLRequest:_cachedRequest];
		_cachedRequest = nil;
	}
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSURLRequest* request = [(DTXRequestsPlaygroundController*)self.windowControllers.firstObject.contentViewController requestForSaving];
	
	return [NSKeyedArchiver archivedDataWithRootObject:request requiringSecureCoding:NO error:outError];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSURLRequest* request = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:outError];
#pragma clang diagnostic pop
	
	if(request == nil)
	{
		return NO;
	}
	
	[self loadRequestDetailsFromURLRequest:request];
	
	return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
