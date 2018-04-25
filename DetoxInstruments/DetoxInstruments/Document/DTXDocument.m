//
//  DTXDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDocument.h"
#import "DTXRecording+UIExtensions.h"
#ifndef CLI
#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteProfilingClient.h"
#import "NSFormatter+PlotFormatters.h"
#endif
#import "AutoCoding.h"
@import ObjectiveC;

NSString * const DTXDocumentDidLoadNotification = @"DTXDocumentDidLoadNotification";
NSString * const DTXDocumentDefactoEndTimestampDidChangeNotification = @"DTXDocumentDefactoEndTimestampDidChangeNotification";
NSString* const DTXDocumentStateDidChangeNotification = @"DTXDocumentStateDidChangeNotification";

static void const * DTXOriginalURLKey = &DTXOriginalURLKey;

@interface DTXDocument ()
#ifndef CLI
<DTXRecordingTargetPickerViewControllerDelegate, DTXRemoteProfilingClientDelegate, DTXRemoteProfilingTargetDelegate>
#endif
{
	NSPersistentContainer* _container;
#ifndef CLI
	__weak DTXRecordingTargetPickerViewController* _recordingTargetPicker;
	DTXRemoteProfilingClient* _remoteProfilingClient;
#endif
}

@property (nonatomic, assign) BOOL isContentsURLTemporary;
@property (nonatomic, strong) NSURL* contentsURL;

@end

@implementation DTXDocument

#ifndef CLI
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	if(item.action == @selector(saveDocument:))
	{
		return self.documentState == DTXDocumentStateLiveRecordingFinished || self.autosavedContentsFileURL != nil;
	}
	
	if(item.action == @selector(duplicateDocument:) || item.action == @selector(moveDocument:) || item.action == @selector(renameDocument:) || item.action == @selector(lockDocument:))
	{
		return self.documentState >= DTXDocumentStateLiveRecordingFinished;
	}
	
	return [super validateUserInterfaceItem:item];
}
#endif

+ (BOOL)autosavesInPlace
{
	return YES;
}

+ (BOOL)preservesVersions
{
	return NO;
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
{
	return NO;
}

- (nullable instancetype)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithType:typeName error:outError];
	
	if(self)
	{
		self.documentState = DTXDocumentStateNew;
	}
	
	return self;
}

- (nullable instancetype)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithContentsOfURL:url ofType:typeName error:outError];
	
	if(self)
	{
		_isContentsURLTemporary = NO;
		_contentsURL = url;
	}
	
	return self;
}

- (nullable instancetype)initForURL:(nullable NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initForURL:urlOrNil withContentsOfURL:contentsURL ofType:typeName error:outError];
	
	if(self)
	{
		_isContentsURLTemporary = NO;
		_contentsURL = contentsURL;
	}
	
	return self;
}

#ifndef CLI
- (void)_prepareForLiveRecording:(DTXRecording*)recording
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_recordingDefactoEndTimestampDidChange:) name:DTXRecordingDidInvalidateDefactoEndTimestamp object:recording];
}

- (void)_prepareForRemoteProfilingRecordingWithTarget:(DTXRemoteProfilingTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	[self _preparePersistenceContainerFromURL:nil allowCreation:YES error:NULL];
	_remoteProfilingClient = [[DTXRemoteProfilingClient alloc] initWithProfilingTarget:target managedObjectContext:_container.viewContext];
	_remoteProfilingClient.delegate = self;
	[_remoteProfilingClient startProfilingWithConfiguration:configuration];
}

- (void)makeWindowControllers
{
	[self addWindowController:[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"InstrumentsWindowController"]];
}
#endif

- (NSURL*)_URLByAppendingStoreCompoenentToURL:(NSURL*)url
{
	return [url URLByAppendingPathComponent:@"_dtx_recording.sqlite"];
}

- (void)setDocumentState:(DTXDocumentState)documentState
{
	_documentState = documentState;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentStateDidChangeNotification object:self];
}

- (BOOL)_preparePersistenceContainerFromURL:(NSURL*)url allowCreation:(BOOL)allowCreation error:(NSError **)outError
{
	NSURL* storeURL = [self _URLByAppendingStoreCompoenentToURL:url];
	
	if(allowCreation == NO && [storeURL checkResourceIsReachableAndReturnError:outError] == NO)
	{
		return NO;
	}
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:storeURL];
	description.type = url ? NSSQLiteStoreType : NSInMemoryStoreType;
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXDocument class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	__block NSError* outerError;
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		if(error)
		{
			outerError = error;
			return;
		}
		
		_container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		DTXRecording* recording = [_container.viewContext executeFetchRequest:[DTXRecording fetchRequest] error:NULL].firstObject;
		
		self.documentState = url != nil && recording != nil ? DTXDocumentStateSavedToDisk : DTXDocumentStateNew;
		
		if(recording == nil)
		{
			return;
		}
		
		_recording = recording;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentDidLoadNotification object:self.windowControllers.firstObject];
		
		//The recording might not have been properly closed by the profiler for several reasons. If no close date, use the last sample as the close date.
		if(_recording.endTimestamp == nil)
		{
			_recording.endTimestamp = _recording.defactoEndTimestamp;
		}
		
#ifndef CLI
		[self _prepareForLiveRecording:_recording];
#endif
	}];
	
	if(outError)
	{
		*outError = outerError;
	}
	
	return outerError == nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	if(url == nil)
	{
		return NO;
	}

	[self _preparePersistenceContainerFromURL:url allowCreation:NO error:outError];
	
	return *outError == nil;
}

- (void)_recordingDefactoEndTimestampDidChange:(NSNotification*)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentDefactoEndTimestampDidChangeNotification object:self];
}

#ifndef CLI
- (void)readyForRecordingIfNeeded
{
	if(self.documentState == DTXDocumentStateNew)
	{
		DTXRecordingTargetPickerViewController* vc = [self.windowControllers.firstObject.storyboard instantiateControllerWithIdentifier:@"DTXRecordingTargetChooser"];
		vc.delegate = self;
		[self.windowControllers.firstObject.window.contentViewController presentViewControllerAsSheet:vc];
		_recordingTargetPicker = vc;
	}
}
#endif

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	if(url != nil && _contentsURL != nil && [url isEqualTo:_contentsURL])
	{
		return YES;
	}
	
	BOOL rv = YES;
	if(_contentsURL)
	{
		if([url checkResourceIsReachableAndReturnError:NULL] == YES)
		{
			if([[NSFileManager defaultManager] removeItemAtURL:url error:outError] == NO)
			{
				return NO;
			}
		}
		
		rv = [[NSFileManager defaultManager] copyItemAtURL:_contentsURL toURL:url error:outError];
	}
	
	if([_container.viewContext save:outError] == NO)
	{
		return NO;
	}
	
	NSPersistentStore* store = _container.persistentStoreCoordinator.persistentStores.firstObject;
	if(rv && [@[@(NSSaveAsOperation), @(NSAutosaveAsOperation), @(NSAutosaveElsewhereOperation)] containsObject:@(saveOperation)])
	{
		if([url checkResourceIsReachableAndReturnError:NULL] == NO)
		{
			if([[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:outError] == NO)
			{
				return NO;
			}
		}
		
		if(saveOperation != NSAutosaveElsewhereOperation || [store.type isEqualToString:NSInMemoryStoreType])
		{
			//This is the only case that NSAutosaveElsewhereOperation is used that modifies the current document. Otherwise, NSAutosaveElsewhereOperation is used for Duplicate.
			_contentsURL = url;
		}
		
		if([store.type isEqualToString:NSInMemoryStoreType])
		{
			rv = nil != [_container.persistentStoreCoordinator migratePersistentStore:store toURL:[self _URLByAppendingStoreCompoenentToURL:url] options:store.options withType:NSSQLiteStoreType error:outError];
		}
		else if(saveOperation != NSAutosaveElsewhereOperation)
		{
			rv = [_container.persistentStoreCoordinator setURL:[self _URLByAppendingStoreCompoenentToURL:url] forPersistentStore:store];
		}
		
		if([_container.viewContext save:outError] == NO)
		{
			return NO;
		}
	}
	
	return rv;
}

- (void)_transitionPersistenceContainerToFileAtURL:(NSURL*)url
{
	if(url == nil)
	{
		return;
	}
	
	_isContentsURLTemporary = NO;
	_contentsURL = url;
	[_container.persistentStoreCoordinator setURL:[self _URLByAppendingStoreCompoenentToURL:url] forPersistentStore:_container.persistentStoreCoordinator.persistentStores.firstObject];
	
	NSURL *trashURL = [[NSFileManager defaultManager] URLForDirectory:NSTrashDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
	
	if([url.absoluteString hasPrefix:trashURL.absoluteString])
	{
		[self close];
	}
}

- (void)setAutosavedContentsFileURL:(NSURL *)autosavedContentsFileURL
{
	[super setAutosavedContentsFileURL:autosavedContentsFileURL];
	
	[self _transitionPersistenceContainerToFileAtURL:autosavedContentsFileURL];
}

- (void)setFileURL:(NSURL *)fileURL
{
	[super setFileURL:fileURL];
	
	[self _transitionPersistenceContainerToFileAtURL:fileURL];
}

- (void)duplicateDocument:(id)sender
{
	[self autosaveWithImplicitCancellability:NO completionHandler:^(NSError * _Nullable errorOrNil) {
		[super duplicateDocument:sender];
	}];
}

- (NSDocument *)duplicateAndReturnError:(NSError **)outError
{
	NSDocument* rv = [super duplicateAndReturnError:outError];
	if(rv)
	{
		rv.displayName = [self.displayName.stringByDeletingPathExtension stringByAppendingString:NSLocalizedString(@" copy", @"")];
	}
	
	return rv;
}

- (NSString *)defaultDraftName
{
	return NSLocalizedString(@"Untitled Recording", @"");
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
#ifndef CLI
	if(self.documentState < DTXDocumentStateLiveRecordingFinished)
	{
		[self stopLiveRecording];
	}
#endif
	
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (void)close
{
	@try {
		if(_container.persistentStoreCoordinator.persistentStores.firstObject != nil)
		{
			[_container.persistentStoreCoordinator removePersistentStore:_container.persistentStoreCoordinator.persistentStores.firstObject error:NULL];
		}
	}
	@catch(NSException* e) {}
	
	[super close];
}

#ifndef CLI
- (void)addTag
{
	[_remoteProfilingClient.target addTagWithName:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];
}

- (void)pushGroup
{
	[_remoteProfilingClient.target pushSampleGroupWithName:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];
}

- (void)popGroup
{
	[_remoteProfilingClient.target popSampleGroup];
}

- (void)stopLiveRecording
{
	[self remoteProfilingClientDidStopRecording:_remoteProfilingClient];
	
	[_remoteProfilingClient.target stopProfiling];
}

#pragma mark DTXRemoteProfilingTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteProfilingTarget *)target {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self remoteProfilingClientDidStopRecording:_remoteProfilingClient];
	});
}

#pragma mark DTXRemoteProfilingClientDelegate

- (void)remoteProfilingClient:(DTXRemoteProfilingClient *)client didCreateRecording:(DTXRecording *)recording
{
	_recording = recording;
	
	[self _prepareForLiveRecording:_recording];
	
	self.documentState = DTXDocumentStateLiveRecording;
	self.displayName = _recording.dtx_profilingConfiguration.recordingFileURL.lastPathComponent.stringByDeletingPathExtension;
	[self.windowControllers.firstObject synchronizeWindowTitleWithDocumentName];
}

- (void)remoteProfilingClientDidStopRecording:(DTXRemoteProfilingClient *)client
{
	if(_recording == nil)
	{
		[self close];
		return;
	}
	
	if(_recording.endTimestamp == nil)
	{
		_recording.endTimestamp = [NSDate date];
	}
	
	self.documentState = DTXDocumentStateLiveRecordingFinished;
	
	[self updateChangeCount:NSChangeDone];
}

- (void)remoteProfilingClientDidChangeDatabase:(DTXRemoteProfilingClient *)client
{
	[_recording invalidateDefactoEndTimestamp];
}

#pragma mark Network Recording Simulation

#pragma mark DTXRecordingTargetPickerViewControllerDelegate

- (void)recordingTargetPickerDidCancel:(DTXRecordingTargetPickerViewController*)picker
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	//If the user opened a new recording window but cancelled recording, close the new document.
	[self close];
}

- (void)recordingTargetPicker:(DTXRecordingTargetPickerViewController*)picker didSelectRemoteProfilingTarget:(DTXRemoteProfilingTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	
	target.delegate = self;
	[self _prepareForRemoteProfilingRecordingWithTarget:target profilingConfiguration:configuration];
}
#endif

@end
