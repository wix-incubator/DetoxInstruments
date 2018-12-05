//
//  DTXRecordingDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXRecordingDocument.h"
#import "DTXRecording+UIExtensions.h"
#ifndef CLI
#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteProfilingClient.h"
#import "NSFormatter+PlotFormatters.h"
#endif
#import "AutoCoding.h"
@import ObjectiveC;

NSString* const DTXRecordingDocumentDidLoadNotification = @"DTXRecordingDocumentDidLoadNotification";
NSString* const DTXRecordingDocumentDefactoEndTimestampDidChangeNotification = @"DTXRecordingDocumentDefactoEndTimestampDidChangeNotification";
NSString* const DTXRecordingDocumentStateDidChangeNotification = @"DTXRecordingDocumentStateDidChangeNotification";

static void const * DTXOriginalURLKey = &DTXOriginalURLKey;

static NSTimeInterval _DTXCurrentRecordingTimeLimit(void)
{
	NSTimeInterval timeLimit = [NSUserDefaults.standardUserDefaults integerForKey:@"DTXSelectedProfilingConfiguration_timeLimit"];
	
	auto mapping = @{@0: @1, @1: @60, @2: @3600};
	NSNumber* type = [NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_timeLimitType"];
	timeLimit *= [mapping[type] doubleValue];
	
	return timeLimit;
}

@interface DTXRecordingDocument ()
#ifndef CLI
<DTXRecordingTargetPickerViewControllerDelegate, DTXRemoteProfilingClientDelegate, DTXRemoteTargetDelegate>
#endif
{
	NSPersistentContainer* _container;
	NSMutableArray<DTXRecording*>* _recordings;
#ifndef CLI
	__weak DTXRecordingTargetPickerViewController* _recordingTargetPicker;
	DTXRemoteProfilingClient* _remoteProfilingClient;
	dispatch_block_t _pendingCancelBlock;
#endif
}

@property (nonatomic, assign) BOOL isContentsURLTemporary;
@property (nonatomic, strong) NSURL* contentsURL;

@end

@implementation DTXRecordingDocument

@synthesize recordings=_recordings;

#ifndef CLI
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	if(item.action == @selector(saveDocument:))
	{
		return self.documentState == DTXRecordingDocumentStateLiveRecordingFinished || self.autosavedContentsFileURL != nil;
	}
	
	if(item.action == @selector(duplicateDocument:) || item.action == @selector(moveDocument:) || item.action == @selector(renameDocument:) || item.action == @selector(lockDocument:))
	{
		return self.documentState >= DTXRecordingDocumentStateLiveRecordingFinished;
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
		self.documentState = DTXRecordingDocumentStateNew;
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

- (void)_prepareForRemoteProfilingRecordingWithTarget:(DTXRemoteTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	[self _preparePersistenceContainerFromURL:nil allowCreation:YES error:NULL];
	NSManagedObjectContext* bgCtx = [_container newBackgroundContext];
	bgCtx.name = @"com.wix.RemoteProfiling-ManagedObjectContext";

	_remoteProfilingClient = [[DTXRemoteProfilingClient alloc] initWithProfilingTarget:target managedObjectContext:bgCtx];
	_remoteProfilingClient.delegate = self;
	[_remoteProfilingClient startProfilingWithConfiguration:configuration];
}

- (void)makeWindowControllers
{
	NSWindowController* wc = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"InstrumentsWindowController"];
	wc.contentViewController = [[NSStoryboard storyboardWithName:@"Profiler" bundle:nil] instantiateInitialController];
	
	[self addWindowController:wc];
}
#endif

- (NSURL*)_URLByAppendingStoreCompoenentToURL:(NSURL*)url
{
	return [url URLByAppendingPathComponent:@"_dtx_recording.sqlite"];
}

- (void)setDocumentState:(DTXRecordingDocumentState)documentState
{
	if(documentState == _documentState)
	{
		return;
	}
	
	_documentState = documentState;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXRecordingDocumentStateDidChangeNotification object:self];
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
	static NSManagedObjectModel* model;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXRecordingDocument class]]]];
	});
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	_container.viewContext.automaticallyMergesChangesFromParent = YES;
	
	__block NSError* outerError;
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		if(error)
		{
			outerError = error;
			return;
		}
		
		_container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		NSFetchRequest* fr = [DTXRecording fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startTimestamp" ascending:YES]];
		
		NSArray<DTXRecording*>* recordings = [_container.viewContext executeFetchRequest:fr error:NULL];
		
		self.documentState = url != nil && recordings.count != 0 ? DTXRecordingDocumentStateSavedToDisk : DTXRecordingDocumentStateNew;
		
		_recordings = [recordings mutableCopy];
		
		if(recordings.count == 0)
		{
			return;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTXRecordingDocumentDidLoadNotification object:self.windowControllers.firstObject];
		
		//The recording might not have been properly closed by the profiler for several reasons. If no close date, use the last sample as the close date.
		if(_recordings.lastObject.endTimestamp == nil)
		{
			_recordings.lastObject.endTimestamp = _recordings.lastObject.defactoEndTimestamp;
		}
		
#ifndef CLI
		[self _prepareForLiveRecording:_recordings.lastObject];
#endif
	}];
	
	if(outError)
	{
		*outError = outerError;
	}
	
	return outerError == nil;
}

- (DTXRecording *)firstRecording
{
	return _recordings.firstObject;
}

- (DTXRecording *)lastRecording
{
	return _recordings.lastObject;
}

- (NSString*)_versionForFlag
{
	return [[NSBundle bundleForClass:self.class] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (void)clearLastOpenedVersionAndReopenDocumentAtURL:(NSURL*)URL
{
	NSURL* versionFlagURL = [URL URLByAppendingPathComponent:@"lastOpenedVersion.txt"];
	[NSFileManager.defaultManager removeItemAtURL:versionFlagURL error:NULL];
	
	[NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:URL display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
		if(error)
		{
			[NSDocumentController.sharedDocumentController presentError:error];
		}
	}];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	if(url == nil)
	{
		return NO;
	}
	
	NSString* currentVersion = self._versionForFlag;
	
	NSURL* versionFlagURL = [url URLByAppendingPathComponent:@"lastOpenedVersion.txt"];
	
	if([versionFlagURL checkResourceIsReachableAndReturnError:NULL])
	{
		NSString* lastOpenedVersion = [NSString stringWithContentsOfURL:versionFlagURL encoding:NSUTF8StringEncoding error:NULL];
		
		if([currentVersion compare:lastOpenedVersion options:NSNumericSearch] == NSOrderedAscending)
		{
			*outError = [NSError errorWithDomain:@"DTXRecordingDocumentErrorDomain"
											code:-9
										userInfo:@{
												   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The document can only be opened safely in a newer version of Detox Instruments.\n\nIf you continue, the recording may be lost or damaged altogether.", @""),
												   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Check for Updates", nil), NSLocalizedString(@"Open Anyway", nil), NSLocalizedString(@"Cancel", nil)],
												   NSRecoveryAttempterErrorKey: self,
												   NSURLErrorKey: url
												   }];
			
			return NO;
		}
	}

	BOOL rv = [self _preparePersistenceContainerFromURL:url allowCreation:NO error:outError];
	
	if(rv)
	{
		[currentVersion writeToURL:versionFlagURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
	
	return rv;
}

- (void)_recordingDefactoEndTimestampDidChange:(NSNotification*)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXRecordingDocumentDefactoEndTimestampDidChangeNotification object:self];
}

#ifndef CLI
- (void)readyForRecordingIfNeeded
{
	if(self.documentState == DTXRecordingDocumentStateNew)
	{
		DTXRecordingTargetPickerViewController* vc = [[NSStoryboard storyboardWithName:@"RemoteProfiling" bundle:NSBundle.mainBundle] instantiateControllerWithIdentifier:@"DTXRecordingTargetChooser"];
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
	return NSLocalizedString(@"New Recording", @"");
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
#ifndef CLI
	if(self.documentState == DTXRecordingDocumentStateLiveRecording)
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
	if(_pendingCancelBlock != nil)
	{
		dispatch_block_cancel(_pendingCancelBlock);
		_pendingCancelBlock = nil;
	}
	
	[self remoteProfilingClientDidStopRecording:_remoteProfilingClient];
	
	[_remoteProfilingClient.target stopProfiling];
}

- (void)_workspaceWillSleepNotification
{
	if(self.documentState == DTXRecordingDocumentStateLiveRecording)
	{
		[self stopLiveRecording];
	}
}

#pragma mark DTXRemoteTargetDelegate

- (void)connectionDidCloseForProfilingTarget:(DTXRemoteTarget *)target {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self remoteProfilingClientDidStopRecording:_remoteProfilingClient];
	});
}

#pragma mark DTXRemoteProfilingClientDelegate

- (void)remoteProfilingClient:(DTXRemoteProfilingClient *)client didCreateRecording:(DTXRecording *)recording
{
	NSManagedObjectID* recordingID = recording.objectID;
	__weak auto weakSelf = self;
	[NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(_workspaceWillSleepNotification) name:NSWorkspaceWillSleepNotification object:nil];
	_pendingCancelBlock = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, QOS_CLASS_USER_INTERACTIVE, 0, ^{
		__strong auto strongSelf = weakSelf;
		if(strongSelf == nil)
		{
			return;
		}
		
		if(strongSelf.documentState == DTXRecordingDocumentStateLiveRecording)
		{
			[strongSelf stopLiveRecording];
		}
	});
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_DTXCurrentRecordingTimeLimit() * NSEC_PER_SEC)), dispatch_get_main_queue(), _pendingCancelBlock);
	
	[_container.viewContext performBlock:^{
		DTXRecording* recording = [_container.viewContext existingObjectWithID:recordingID error:NULL];
		
		[_recordings addObject:recording];
		
		[self _prepareForLiveRecording:recording];
		
		self.documentState = DTXRecordingDocumentStateLiveRecording;
		self.displayName = recording.dtx_profilingConfiguration.recordingFileURL.lastPathComponent.stringByDeletingPathExtension;
		[self.windowControllers.firstObject synchronizeWindowTitleWithDocumentName];
	}];
}

- (void)remoteProfilingClient:(DTXRemoteProfilingClient *)client didReceiveSourceMapsData:(NSData *)sourceMapsData
{
	NSError* error;
	NSDictionary<NSString*, id>* sourceMaps = [NSJSONSerialization JSONObjectWithData:sourceMapsData options:0 error:&error];
	if(sourceMaps == nil)
	{
		NSLog(@"Error parsing source maps: %@", error);
		return;
	}
	
	_sourceMapsParser = [DTXSourceMapsParser sourceMapsParserForSourceMaps:sourceMaps];
}

- (void)remoteProfilingClientDidStopRecording:(DTXRemoteProfilingClient *)client
{
	[self updateChangeCount:NSChangeDone];
	
	[_remoteProfilingClient stopWithCompletionHandler:nil];
	
	[_container.viewContext performBlock:^{
		if(self.lastRecording == nil)
		{
			[self close];
			return;
		}
		
		if(self.lastRecording.endTimestamp == nil)
		{
			self.lastRecording.endTimestamp = [NSDate date];
		}
		
		//Autosave here so that the Core Data container moves to SQL type and only then update document state.
		[self autosaveWithImplicitCancellability:self.autosavingIsImplicitlyCancellable completionHandler:^(NSError * _Nullable errorOrNil) {
			self.documentState = DTXRecordingDocumentStateLiveRecordingFinished;
		}];
	}];
	
	_remoteProfilingClient = nil;
}

- (void)remoteProfilingClientDidChangeDatabase:(DTXRemoteProfilingClient *)client
{
	[_container.viewContext performBlock:^{
		[self.lastRecording invalidateDefactoEndTimestamp];
	}];
}

#pragma mark Network Recording Simulation

#pragma mark DTXRecordingTargetPickerViewControllerDelegate

- (void)recordingTargetPickerDidCancel:(DTXRecordingTargetPickerViewController*)picker
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	//If the user opened a new recording window but cancelled recording, close the new document.
	[self close];
}

- (void)recordingTargetPicker:(DTXRecordingTargetPickerViewController*)picker didSelectRemoteProfilingTarget:(DTXRemoteTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	
	target.delegate = self;
	[self _prepareForRemoteProfilingRecordingWithTarget:target profilingConfiguration:configuration];
}
#endif

#pragma mark NSErrorRecoveryAttempting

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
	if([error.domain isEqualToString:@"DTXRecordingDocumentErrorDomain"] == NO)
	{
		return NO;
	}
	
	switch(recoveryOptionIndex)
	{
		case 0:
			[NSApp sendAction:NSSelectorFromString(@"checkForUpdates:") to:nil from:nil];
			break;
		case 1:
			[self.class clearLastOpenedVersionAndReopenDocumentAtURL:error.userInfo[NSURLErrorKey]];
			break;
	}
	
	return NO;
}

@end
