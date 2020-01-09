//
//  DTXRecordingDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "DTXRecordingDocument.h"
#import "DTXRecording+UIExtensions.h"
#import "NSURL+UIAdditions.h"
#import "NSString+FileNames.h"
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
#import "_DTXLaunchProfilingDiscovery.h"
#import "DTXRecordingTargetPickerViewController.h"
#import "DTXRemoteProfilingClient.h"
#import "DTXRemoteLaunchProfilingClient.h"
#import "NSFormatter+PlotFormatters.h"
#import "DTXLogging.h"
#import "DTXZipper.h"
#import "DTXProfilingConfiguration-Private.h"
DTX_CREATE_LOG(RecordingDocument)
#else
#define dtx_log_info(a, b)
#endif
#import "AutoCoding.h"
@import ObjectiveC;

NSString* const DTXRecordingDocumentDidLoadNotification = @"DTXRecordingDocumentDidLoadNotification";
NSString* const DTXRecordingDocumentDefactoEndTimestampDidChangeNotification = @"DTXRecordingDocumentDefactoEndTimestampDidChangeNotification";
NSString* const DTXRecordingDocumentStateDidChangeNotification = @"DTXRecordingDocumentStateDidChangeNotification";
NSString* const DTXRecordingLocalRecordingProfilingStateDidChangeNotification = @"DTXRecordingLocalRecordingProfilingStateDidChangeNotification";

static void const * DTXOriginalURLKey = &DTXOriginalURLKey;

typedef NS_ENUM(NSUInteger, DTXRecordingDocumentMigrationState) {
	DTXRecordingDocumentMigrationStateEnded,
	DTXRecordingDocumentMigrationStateStarted,
};

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
static NSTimeInterval _DTXCurrentRecordingTimeLimit(void)
{
	NSTimeInterval timeLimit = [NSUserDefaults.standardUserDefaults integerForKey:@"DTXSelectedProfilingConfiguration_timeLimit"];
	
	auto mapping = @{@0: @1, @1: @60, @2: @3600};
	NSNumber* type = [NSUserDefaults.standardUserDefaults objectForKey:@"DTXSelectedProfilingConfiguration_timeLimitType"];
	timeLimit *= [mapping[type] doubleValue];
	
	return timeLimit;
}
#endif

@interface DTXRecordingDocument ()
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
<DTXRecordingTargetPickerViewControllerDelegate, DTXRemoteProfilingClientDelegate, DTXRemoteLaunchProfilingClientDelegate, DTXRemoteTargetDelegate>
#endif
{
	NSPersistentContainer* _container;
	NSMutableArray<DTXRecording*>* _recordings;
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
	DTXRemoteProfilingClient* _remoteProfilingClient;
	DTXRemoteLaunchProfilingClient* _remoteLaunchProfilingClient;
	dispatch_block_t _pendingCancelBlock;
	
	id _liveRecordingActivity;
	
	id _pendingCloseDelegate;
	SEL _pendingCloseSelector;
	id _pendingCloseContext;
#endif
	
	BOOL _duplicatingBecauseOfVersionMismatch;
}

@property (nonatomic, strong) NSURL* contentsURL;

@end

@implementation DTXRecordingDocument

@synthesize recordings=_recordings;

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
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
		_contentsURL = url;
	}
	
	return self;
}

- (nullable instancetype)initForURL:(nullable NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initForURL:urlOrNil withContentsOfURL:contentsURL ofType:typeName error:outError];
	
	if(self)
	{
		_contentsURL = contentsURL;
	}
	
	return self;
}

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
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

- (void)_prepareForRemoteLocalProfilingRecordingWithTarget:(DTXRemoteTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	_localRecordingPendingAppName = target.appName;
	self.localRecordingProfilingState = DTXRecordingLocalRecordingProfilingStateWaitingForAppData;
	self.documentState = DTXRecordingDocumentStateLiveRecording;
	
	_remoteProfilingClient = [[DTXRemoteProfilingClient alloc] initWithProfilingTargetForLocalRecording:target];
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

- (void)setLocalRecordingProfilingState:(DTXRecordingLocalRecordingProfilingState)localRecordingProfilingState
{
	if(_localRecordingProfilingState == localRecordingProfilingState)
	{
		return;
	}
	
	_localRecordingProfilingState = localRecordingProfilingState;
	
	[NSNotificationCenter.defaultCenter postNotificationName:DTXRecordingLocalRecordingProfilingStateDidChangeNotification object:self];
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

- (NSError*)_errorForMigrationFailure
{
	return [NSError errorWithDomain:@"DTXRecordingDocumentErrorDomain"
							   code:-9
						   userInfo:@{
							   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This document is not supported by the current version of Detox Instruments.", @""),
							   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try opening the document in an older version of Detox Instruments", @""),
						   }];
}

- (BOOL)_requiresMigrationForURL:(NSURL*)sourceStoreURL toModel:(NSManagedObjectModel *)finalModel
{
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceStoreURL options:nil error:NULL];
	
	if(sourceMetadata == nil)
	{
		return YES;
	}
	
	if ([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata] == YES)
	{
		return NO;
	}
	
	return YES;
}

- (BOOL)_progressivelyMigrateURL:(NSURL *)sourceStoreURL toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error progressHandler:(void(^)(DTXRecordingDocumentMigrationState migrationState, NSDictionary* userInfo))progressHandler
{
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceStoreURL options:nil error:error];
	
	if (sourceMetadata == nil)
	{
		return NO;
	}
	
	if ([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata] == YES)
	{
		progressHandler(DTXRecordingDocumentMigrationStateEnded, nil);
		*error = nil;
		return YES;
	}
	
	progressHandler(DTXRecordingDocumentMigrationStateStarted, nil);
	
	NSArray* bundles = DTXInstrumentsUtils.bundlesForObjectModel;
	
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundles forStoreMetadata:sourceMetadata];
	if(sourceModel == nil)
	{
		*error = self._errorForMigrationFailure;
		return NO;
	}
	
	NSBundle* bundle = bundles.firstObject;
	
	NSMutableArray* modelPaths = [NSMutableArray array];
	NSArray* momdPaths = [bundle pathsForResourcesOfType:@"momd" inDirectory:nil];
	
	for(NSString* momdPath in momdPaths)
	{
		NSString* resourceSubpath = momdPath.lastPathComponent;
		NSArray* momPaths = [bundle pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
		[modelPaths addObjectsFromArray:momPaths];
	}
	
	NSArray* otherModels = [bundle pathsForResourcesOfType:@"mom" inDirectory:nil];
	[modelPaths addObjectsFromArray:otherModels];
	
	if (modelPaths.count == 0)
	{
		*error = self._errorForMigrationFailure;
		return NO;
	}
	
	NSMappingModel* mappingModel = nil;
	NSManagedObjectModel* targetModel = nil;
	NSString* modelPath = nil;
	NSArray* bundlesForTargetModel = @[bundle];
	
	for(modelPath in modelPaths)
	{
		targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
		
		if([targetModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata] == YES)
		{
			continue;
		}
		
		mappingModel = [NSMappingModel mappingModelFromBundles:bundlesForTargetModel forSourceModel:sourceModel destinationModel:targetModel];
		
		if(mappingModel != nil)
		{
			break;
		}
	}
	
	if (mappingModel == nil)
	{
		*error = self._errorForMigrationFailure;
		return NO;
	}
	
	NSMigrationManager* manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:targetModel];
	NSString* localModelName = [[modelPath lastPathComponent] stringByDeletingPathExtension];
	
	dtx_log_info(@"Migrating to %@", localModelName);
	
	NSString* storeExtension = sourceStoreURL.pathExtension;
	NSURL* destinationStoreURL = sourceStoreURL.URLByDeletingPathExtension;
	
	destinationStoreURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.%@.%@", destinationStoreURL.path, localModelName, storeExtension]];
	if (![manager migrateStoreFromURL:sourceStoreURL type:NSSQLiteStoreType options:@{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}, NSSQLiteManualVacuumOption: @YES, NSSQLiteAnalyzeOption: @YES} withMappingModel:mappingModel toDestinationURL:destinationStoreURL destinationType:NSSQLiteStoreType destinationOptions:@{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}, NSSQLiteManualVacuumOption: @YES, NSSQLiteAnalyzeOption: @YES} error:error])
	{
		return NO;
	}
	
	NSURL* walURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@-wal", sourceStoreURL.path]];
	NSURL* shmURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@-shm", sourceStoreURL.path]];
	
	[NSFileManager.defaultManager removeItemAtURL:sourceStoreURL error:NULL];
	[NSFileManager.defaultManager removeItemAtURL:walURL error:NULL];
	[NSFileManager.defaultManager removeItemAtURL:shmURL error:NULL];
	
	[NSFileManager.defaultManager moveItemAtURL:destinationStoreURL toURL:sourceStoreURL error:NULL];
	
	return [self _progressivelyMigrateURL:sourceStoreURL toModel:finalModel error:error progressHandler:progressHandler];
}

- (BOOL)_preparePersistenceContainerFromURL:(NSURL*)url allowCreation:(BOOL)allowCreation error:(NSError **)outError
{
	NSURL* storeURL = [self _URLByAppendingStoreCompoenentToURL:url];
	
	if(allowCreation == NO && [storeURL checkResourceIsReachableAndReturnError:outError] == NO)
	{
		return NO;
	}
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:storeURL];
#if PROFILER_PREVIEW_EXTENSION
	[description setOption:@YES forKey:NSReadOnlyPersistentStoreOption];
#endif
	description.type = url ? NSSQLiteStoreType : NSInMemoryStoreType;
	static NSManagedObjectModel* model;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		model = [NSManagedObjectModel mergedModelFromBundles:DTXInstrumentsUtils.bundlesForObjectModel];
	});
	
	if(storeURL != nil && [self _requiresMigrationForURL:storeURL toModel:model] == YES)
	{
		NSDictionary* values = [url resourceValuesForKeys:@[NSURLIsSystemImmutableKey, NSURLIsUserImmutableKey] error:outError];
		if(*outError != nil)
		{
			return NO;
		}
		
		BOOL isLocked = [values[NSURLIsSystemImmutableKey] boolValue] == YES || [values[NSURLIsUserImmutableKey] boolValue] == YES;
		//Check that any of the internal files isns't also locked.
		if(isLocked == NO)
		{
			NSDirectoryEnumerator* enumerator = [NSFileManager.defaultManager enumeratorAtURL:url includingPropertiesForKeys:nil options:0 errorHandler:nil];
			
			for(NSURL* fileURL in enumerator)
			{
				values = [fileURL resourceValuesForKeys:@[NSURLIsSystemImmutableKey, NSURLIsUserImmutableKey] error:outError];
				if(*outError != nil)
				{
					return NO;
				}
				
				isLocked |= [values[NSURLIsSystemImmutableKey] boolValue] == YES || [values[NSURLIsUserImmutableKey] boolValue] == YES;
			}
		}
		
		if(isLocked)
		{
			NSError* err = [NSError errorWithDomain:@"DTXRecordingDocumentErrorDomain"
											   code:-9
										   userInfo:@{
											   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The document requires data migration but is locked.", @""),
											   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Duplicate the document to migrate it safely.", @""),
											   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Duplicate", nil), NSLocalizedString(@"Cancel", nil)],
											   NSRecoveryAttempterErrorKey: self,
											   NSURLErrorKey: url,
											   @"DTXDuplicateIndex": @0,
										   }];
			
			if(NSApp != nil)
			{
				[NSApp presentError:err];
				
				*outError = [NSError errorWithDomain:@"DTXRecordingDocumentIgnoredErrorDomain" code:0 userInfo:nil];
			}
			else
			{
				*outError = err;
			}
			
			return NO;
		}
		
		static NSDateFormatter* df;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			df = [NSDateFormatter new];
			df.dateStyle = NSDateFormatterShortStyle;
			df.timeStyle = NSDateFormatterShortStyle;
			df.dateFormat = @"yyyy-MM-dd HH_mm_ss";
		});
		
		//Copy document to a temporary folder and try to migrate the temporary document.
		NSURL* tempURL = [NSURL.temporaryDirectoryURL URLByAppendingPathComponent:url.lastPathComponent];
		[[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
		
		NSURL* documentsDirURL = [[NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:@"Detox Instruments" isDirectory:YES];
		NSURL* backupURL = [[documentsDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ (Before Migration %@)", url.URLByDeletingPathExtension.lastPathComponent, [df stringFromDate:NSDate.date].stringBySanitizingForFileName]] URLByAppendingPathExtension:url.pathExtension];
		if([[NSFileManager defaultManager] copyItemAtURL:url toURL:tempURL error:outError] == NO)
		{
			return NO;
		}
		dtx_defer {
			[[NSFileManager defaultManager] removeItemAtURL:tempURL error:NULL];
		};
		
		NSURL* tempStoreURL = [self _URLByAppendingStoreCompoenentToURL:tempURL];
		
#if ! CLI
		NSWindowController* modalWindowController = [[NSStoryboard storyboardWithName:@"Profiler" bundle:[NSBundle bundleForClass:self.class]] instantiateControllerWithIdentifier:@"migrationIndicator"];
		__block NSModalSession modalSession = NULL;
#endif
		BOOL didMigrate = [self _progressivelyMigrateURL:tempStoreURL toModel:model error:outError progressHandler:^(DTXRecordingDocumentMigrationState migrationState, NSDictionary *userInfo) {
#if ! CLI
			if(migrationState == DTXRecordingDocumentMigrationStateEnded)
			{
				if(modalSession != NULL)
				{
					[NSApp endModalSession:modalSession];
					[modalWindowController.window close];
				}
				modalSession = NULL;
			}
			else if(migrationState == DTXRecordingDocumentMigrationStateStarted)
			{
				if(modalSession == NULL)
				{
					modalSession = [NSApp beginModalSessionForWindow:modalWindowController.window];
					[NSApp runModalSession:modalSession];
				}
			}
#endif
		}];
		
#if ! CLI
		if(modalSession != NULL)
		{
			[NSApp endModalSession:modalSession];
			[modalWindowController.window close];
		}
		modalSession = NULL;
#endif
		
		if(didMigrate == YES)
		{
			NSURL* autosavedInformationURL = [NSFileManager.defaultManager URLForDirectory:NSAutosavedInformationDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
			
			//Only create a backup if not under the autosave information folder (duplicated document during migration).
			if([backupURL.path hasPrefix:autosavedInformationURL.path] == NO)
			{
				[NSFileManager.defaultManager createDirectoryAtURL:documentsDirURL withIntermediateDirectories:YES attributes:nil error:NULL];
				[[NSFileManager defaultManager] removeItemAtURL:backupURL error:NULL];
				[[NSFileManager defaultManager] copyItemAtURL:url toURL:backupURL error:NULL];
			}
			
			//Replace current document with the migrated copy.
			if([[NSFileManager defaultManager] removeItemAtURL:url error:outError] == NO || [[NSFileManager defaultManager] copyItemAtURL:tempURL toURL:url error:outError] == NO)
			{
				return NO;
			}
		}
		else
		{
			return NO;
		}
	}
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	__block NSError* somewhatInnerError;
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		if(error)
		{
			somewhatInnerError = error;
			return;
		}
		
		dtx_defer {
			self.documentState = url != nil && _recordings.count != 0 ? DTXRecordingDocumentStateSavedToDisk : DTXRecordingDocumentStateNew;
		};
		
		_container.viewContext.automaticallyMergesChangesFromParent = YES;
		_container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		NSFetchRequest* fr = [DTXRecording fetchRequest];
		fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startTimestamp" ascending:YES]];
		
		NSArray<DTXRecording*>* recordings = [_container.viewContext executeFetchRequest:fr error:NULL];
		
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
		
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
		[self _prepareForLiveRecording:_recordings.lastObject];
#endif
	}];
	
	if(outError)
	{
		*outError = somewhatInnerError;
	}
	
	return somewhatInnerError == nil;
}

- (DTXRecording *)firstRecording
{
	return _recordings.firstObject;
}

- (DTXRecording *)lastRecording
{
	return _recordings.lastObject;
}

- (NSManagedObjectContext *)viewContext
{
	return _container.viewContext;
}

- (NSManagedObjectContext *)newBackgroundContext
{
	return [_container newBackgroundContext];
}

- (void)performBackgroundTask:(void (^)(NSManagedObjectContext *))block
{
	[_container performBackgroundTask:block];
}

+ (void)clearLastOpenedVersionAtURL:(NSURL*)URL
{
	NSURL* versionFlagURL = [URL URLByAppendingPathComponent:@"lastOpenedVersion.txt"];
	[NSFileManager.defaultManager removeItemAtURL:versionFlagURL error:NULL];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	if(url == nil)
	{
		return NO;
	}
	
	NSString* currentVersion = DTXInstrumentsUtils.applicationVersion;
	
	NSURL* versionFlagURL = [url URLByAppendingPathComponent:@"lastOpenedVersion.txt"];
	
	if([NSProcessInfo.processInfo.arguments containsObject:@"--force"] || [NSProcessInfo.processInfo.arguments containsObject:@"-f"])
	{
		[self.class clearLastOpenedVersionAtURL:url];
	}
	else
	{
		if([versionFlagURL checkResourceIsReachableAndReturnError:NULL])
		{
			NSString* lastOpenedVersion = [NSString stringWithContentsOfURL:versionFlagURL encoding:NSUTF8StringEncoding error:NULL];
			
			if([currentVersion compare:lastOpenedVersion options:NSNumericSearch] == NSOrderedAscending)
			{
				NSError* err = [NSError errorWithDomain:@"DTXRecordingDocumentErrorDomain"
												   code:-9
											   userInfo:@{
												   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"A newer version of Detox Instruments is required to open the document safely.", @""),
												   NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"The document was last opened with Detox Instruments version %@.\n\nIf you wish to open the document anyway, select “Duplicate”. Some data might not be correctly loaded or the entire operation may fail altogether.", @""), lastOpenedVersion],
#if ! PROFILER_PREVIEW_EXTENSION
												   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Check for Updates", nil), NSLocalizedString(@"Duplicate", nil), NSLocalizedString(@"Cancel", nil)],
												   NSRecoveryAttempterErrorKey: self,
												   NSURLErrorKey: url,
												   @"DTXCheckForUpdatesIndex": @0,
												   @"DTXDuplicateIndex": @1,
#endif
											   }];
				
#if ! PROFILER_PREVIEW_EXTENSION
				if(NSApp != nil)
				{
					[NSApp presentError:err];
					*outError = [NSError errorWithDomain:@"DTXRecordingDocumentIgnoredErrorDomain" code:0 userInfo:nil];
				}
				else
				{
#endif
					*outError = err;
#if ! PROFILER_PREVIEW_EXTENSION
				}
#endif
				return NO;
			}
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

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
- (void)readyForRecordingIfNeeded
{
	if(self.documentState == DTXRecordingDocumentStateNew)
	{
		DTXRecordingTargetPickerViewController* vc = [[NSStoryboard storyboardWithName:@"RemoteProfiling" bundle:NSBundle.mainBundle] instantiateControllerWithIdentifier:@"DTXRecordingTargetChooser"];
		vc.delegate = self;
		[self.windowControllers.firstObject.window.contentViewController presentViewControllerAsSheet:vc];
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
		
		if(_duplicatingBecauseOfVersionMismatch == YES)
		{
			if([url setResourceValue:@NO forKey:NSURLIsUserImmutableKey error:outError] == NO)
			{
				return NO;
			}
			
			NSDirectoryEnumerator* enumerator = [NSFileManager.defaultManager enumeratorAtURL:url includingPropertiesForKeys:nil options:0 errorHandler:nil];
			
			//When duplicating, make sure internal files are not locked.
			for(NSURL* fileURL in enumerator)
			{
				if([fileURL setResourceValue:@NO forKey:NSURLIsUserImmutableKey error:outError] == NO)
				{
					return NO;
				}
			}
			
			[self.class clearLastOpenedVersionAtURL:url];
			_duplicatingBecauseOfVersionMismatch = NO;
		}
	}
	
	if(_container == nil)
	{
		//There is no container, so create a new directory in the place of the files.
		return [NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:outError];
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
	
	if([_contentsURL isEqualTo:url])
	{
		return;
	}
	
	_contentsURL = url;
	[_container.persistentStoreCoordinator setURL:[self _URLByAppendingStoreCompoenentToURL:url] forPersistentStore:_container.persistentStoreCoordinator.persistentStores.firstObject];
	
	NSURL *trashURL = [NSFileManager.defaultManager URLForDirectory:NSTrashDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
	
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
#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
	if(self.documentState == DTXRecordingDocumentStateLiveRecording)
	{
		[self stopLiveRecording];
		_pendingCloseDelegate = delegate;
		_pendingCloseSelector = shouldCloseSelector;
		_pendingCloseContext = NS(contextInfo);
		
		return;
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

#if ! CLI && ! PROFILER_PREVIEW_EXTENSION
- (void)addTag
{
	[_remoteProfilingClient.target addTagWithName:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];
}

- (void)stopLiveRecording
{
	if(_pendingCancelBlock != nil)
	{
		dispatch_block_cancel(_pendingCancelBlock);
		_pendingCancelBlock = nil;
	}
	
	[_remoteProfilingClient stopProfiling];
}

- (BOOL)allowsDocumentSharing
{
	return self.documentState >= DTXRecordingDocumentStateLiveRecordingFinished;
}

- (void)dealloc
{
	[_remoteProfilingClient stopProfiling];
	[_remoteLaunchProfilingClient stop];
}

- (void)_loadZippedData:(NSData*)zippedData completionHandler:(dispatch_block_t)completionHandler
{
	[self autosaveWithImplicitCancellability:YES completionHandler:^(NSError * _Nullable errorOrNil) {
		dtx_defer {
			self.localRecordingProfilingState = DTXRecordingLocalRecordingProfilingStateUnknown;
		};
		
		if(errorOrNil)
		{
			[self presentError:errorOrNil];
			
			[self close];
			
			return;
		}
		
		DTXExtractDataZipToURL(zippedData, self.contentsURL);
		
		if(NO == [self _preparePersistenceContainerFromURL:self.contentsURL allowCreation:NO error:&errorOrNil])
		{
			[self presentError:errorOrNil];
			
			[self close];
			
			return;
		}
		
		if(completionHandler)
		{
			completionHandler();
		}
	}];
}

#pragma mark DTXRemoteProfilingClientDelegate

- (void)remoteProfilingClient:(DTXRemoteProfilingClient *)client didCreateRecording:(DTXRecording *)recording
{
	NSManagedObjectID* recordingID = recording.objectID;
	__weak auto weakSelf = self;
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
		_liveRecordingActivity = [NSProcessInfo.processInfo beginActivityWithOptions:NSActivityUserInitiated reason:@"Live Recroding"];
		
		DTXRecording* recording = [_container.viewContext existingObjectWithID:recordingID error:NULL];
		
		[_recordings addObject:recording];
		
		[self _prepareForLiveRecording:recording];
		
		self.documentState = DTXRecordingDocumentStateLiveRecording;
		self.displayName = [DTXProfilingConfiguration _urlForNewRecordingWithAppName:recording.appName date:recording.startTimestamp].lastPathComponent.stringByDeletingPathExtension;
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

- (void)remoteProfilingClient:(DTXRemoteProfilingClient*)client didStopRecordingWithZippedRecordingData:(NSData*)zippedData
{
	[self updateChangeCount:NSChangeDone];
	if(_liveRecordingActivity)
	{
		[NSProcessInfo.processInfo endActivity:_liveRecordingActivity];
		_liveRecordingActivity = nil;
	}
	
	if(zippedData)
	{
		[self _loadZippedData:zippedData completionHandler: ^ {
			self.displayName = [DTXProfilingConfiguration _urlForNewRecordingWithAppName:self.recordings.firstObject.appName date:self.recordings.firstObject.startTimestamp].lastPathComponent.stringByDeletingPathExtension;
			[self.windowControllers.firstObject synchronizeWindowTitleWithDocumentName];
			
			if(_pendingCloseDelegate)
			{
				[super canCloseDocumentWithDelegate:_pendingCloseDelegate shouldCloseSelector:_pendingCloseSelector contextInfo:PTR(_pendingCloseContext)];
				_pendingCloseDelegate = nil;
				_pendingCloseContext = nil;
			}
		}];
	}
	else
	{
		NSError* err = [NSError errorWithDomain:@"DTXRecordingDocumentErrorDomain" code:-9 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to display recording document.", @""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The profiled app disconnected without providing the recorded data.\n\nThe recording document may still be available in the Documents folder in your app's container.", @"") }];
		
		if(self.localRecordingProfilingState != DTXRecordingLocalRecordingProfilingStateUnknown)
		{			
			[self.windowControllers.firstObject presentError:err];
			[self close];
		}
		
		[_container.viewContext performBlock:^{
			if(self.lastRecording == nil)
			{
				[self.windowControllers.firstObject presentError:err];
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
				
				if(_pendingCloseDelegate)
				{
					[super canCloseDocumentWithDelegate:_pendingCloseDelegate shouldCloseSelector:_pendingCloseSelector contextInfo:PTR(_pendingCloseContext)];
					_pendingCloseDelegate = nil;
					_pendingCloseContext = nil;
				}
			}];
		}];
	}
	
	_remoteProfilingClient.delegate = nil;
	_remoteProfilingClient = nil;
}

- (void)remoteProfilingClientDidChangeDatabase:(DTXRemoteProfilingClient *)client
{
	[_container.viewContext performBlock:^{
		[self.lastRecording invalidateDefactoEndTimestamp];
	}];
}

#pragma mark DTXRemoteLaunchProfilingClientDelegate

- (void)remoteLaunchProfilingClientDidConnect:(DTXRemoteLaunchProfilingClient*)client
{
	self.localRecordingProfilingState = DTXRecordingLocalRecordingProfilingStateWaitingForAppData;
}

- (void)remoteLaunchProfilingClient:(DTXRemoteLaunchProfilingClient*)client didFinishLaunchProfilingWithZippedData:(NSData*)zippedData
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_remoteLaunchProfilingClient stop];
		_remoteLaunchProfilingClient.delegate = nil;
		_remoteLaunchProfilingClient = nil;
		
		[self updateChangeCount:NSChangeDone];
		[self _loadZippedData:zippedData completionHandler:^ {
			self.displayName = [DTXProfilingConfiguration _urlForLaunchRecordingWithAppName:self.recordings.firstObject.appName date:self.recordings.firstObject.startTimestamp].lastPathComponent.stringByDeletingPathExtension;
			[self.windowControllers.firstObject synchronizeWindowTitleWithDocumentName];
		}];
	});
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
	
	if(configuration.recordActivity == NO)
	{
		[self _prepareForRemoteProfilingRecordingWithTarget:target profilingConfiguration:configuration];
	}
	else
	{
		[self _prepareForRemoteLocalProfilingRecordingWithTarget:target profilingConfiguration:configuration];
	}
}

- (void)recordingTargetPicker:(DTXRecordingTargetPickerViewController*)picker didSelectRemoteProfilingTargetForLaunchProfiling:(DTXRemoteTarget*)target profilingConfiguration:(DTXProfilingConfiguration*)configuration
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	
	_localRecordingPendingAppName = target.appName;
	
	NSTimeInterval duration = [NSUserDefaults.standardUserDefaults doubleForKey:@"DTXPreferencesLaunchProfilingDuration"];
	NSString* session = NSUUID.UUID.UUIDString;
	
	[target requestLaunchProfilingWithSessionID:session configuration:configuration duration:duration];
	
	_remoteLaunchProfilingClient = [[DTXRemoteLaunchProfilingClient alloc] initWithLaunchProfilingSessionID:session];
	_remoteLaunchProfilingClient.delegate = self;
	[_remoteLaunchProfilingClient startConnecting];
	
	self.localRecordingProfilingState = DTXRecordingLocalRecordingProfilingStateWaitingForAppLaunch;
}

#endif

#pragma mark NSErrorRecoveryAttempting

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
	if([error.domain isEqualToString:@"DTXRecordingDocumentErrorDomain"] == NO)
	{
		return NO;
	}
	
	/*
	 @"DTXCheckForUpdatesIndex": @999,
	 @"DTXDuplicateIndex": @0,
	 */
	
	NSUInteger checkForUpdatesIndex = [(error.userInfo[@"DTXCheckForUpdatesIndex"] ?: @999) unsignedIntegerValue];
	NSUInteger duplicateIndex = [(error.userInfo[@"DTXDuplicateIndex"] ?: @998) unsignedIntegerValue];
	
	if(recoveryOptionIndex == checkForUpdatesIndex)
	{
		[NSApp sendAction:NSSelectorFromString(@"checkForUpdates:") to:nil from:nil];
	}
	else if(recoveryOptionIndex == duplicateIndex)
	{
		_duplicatingBecauseOfVersionMismatch = YES;
		NSError* dupError = nil;
		DTXRecordingDocument* duplicate = [self duplicateAndReturnError:&dupError];
		
		if(duplicate != nil)
		{
			[NSDocumentController.sharedDocumentController addDocument:duplicate];
		}
		else
		{
			[NSApp presentError:dupError];
		}
	}
	
	return NO;
}

@end

@interface DTXLegacyRecordingDocument : DTXRecordingDocument @end
@implementation DTXLegacyRecordingDocument @end
