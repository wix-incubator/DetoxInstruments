//
//  DTXDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDocument.h"
@import ObjectiveC;

NSString * const DTXDocumentDidLoadNotification = @"DTXDocumentDidLoadNotification";

static void const * DTXOriginalURLKey = &DTXOriginalURLKey;

@interface NSFileWrapper (URLExpose)

@property (nonatomic, strong, readonly) NSURL* dtx_originalURL;

@end
@implementation NSFileWrapper (URLExpose)

- (NSURL *)dtx_originalURL
{
	return objc_getAssociatedObject(self, DTXOriginalURLKey);
}

- (instancetype)_swz_initWithURL:(NSURL *)url options:(NSFileWrapperReadingOptions)options error:(NSError * _Nullable __autoreleasing *)outError
{
	id rv = [self _swz_initWithURL:url options:options error:outError];
	
	objc_setAssociatedObject(rv, DTXOriginalURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	return rv;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getInstanceMethod([NSFileWrapper class], @selector(initWithURL:options:error:));
		Method m2 = class_getInstanceMethod([NSFileWrapper class], @selector(_swz_initWithURL:options:error:));
		
		method_exchangeImplementations(m1, m2);
	});
}

@end

@interface DTXDocument ()
{
	NSPersistentContainer* _container;
}

@end

@implementation DTXDocument

- (instancetype)init
{
    self = [super init];
    if (self)
	{
		// Add your subclass-specific initialization here.
    }
    return self;
}

+ (BOOL)autosavesInPlace
{
	return YES;
}


- (void)makeWindowControllers
{
	[self addWindowController:[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"InstrumentsWindowController"]];
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[fileWrapper.fileWrappers[@"_dtx_recording.sqlite"] dtx_originalURL]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXDocument class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		_recording = [_container.viewContext executeFetchRequest:[DTXRecording fetchRequest] error:NULL].firstObject;
		[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentDidLoadNotification object:self.windowControllers.firstObject];
		
		//The recording might not have been properly closed by the profiler for several reasons. If no close date, use the last sample as the close date.
		if(_recording.endTimestamp == nil)
		{
			NSFetchRequest<DTXSample*>* fr = [DTXSample fetchRequest];
			fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
			fr.fetchLimit = 1;
			
			[_container.viewContext performBlockAndWait:^{
				_recording.endTimestamp = [fr execute:NULL].firstObject.timestamp;
			}];
		}
	}];
	
	return YES;
}

@end
