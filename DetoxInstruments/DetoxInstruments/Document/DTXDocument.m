//
//  DTXDocument.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 22/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "DTXDocument.h"
#import "DTXRecording+UIExtensions.h"
#import "DTXRecordingTargetPickerViewController.h"
@import ObjectiveC;

NSString * const DTXDocumentDidLoadNotification = @"DTXDocumentDidLoadNotification";
NSString * const DTXDocumentDefactoEndTimestampDidChangeNotification = @"DTXDocumentDefactoEndTimestampDidChangeNotification";

static void const * DTXOriginalURLKey = &DTXOriginalURLKey;

@interface DTXDocument () <DTXRecordingTargetPickerViewControllerDelegate>
{
	NSPersistentContainer* _container;
	__weak DTXRecordingTargetPickerViewController* _recordingTargetPicker;
#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
	DTXRecording* _actualRecording;
	NSTimer* _simulatedRecordingTimer;
	NSDate* _timerStartDate;
	NSDate* _previousTickDate;
	DTXSampleGroup* _simulatedGroup;
#endif
}

@end

@implementation DTXDocument

- (nullable instancetype)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithType:typeName error:outError];
	
	if(self)
	{
		self.documentType = DTXDocumentTypeNone;
	}
	
	return self;
}

- (void)_prepareForRecording:(DTXRecording*)recording
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_recordingDefactoEndTimestampDidChange:) name:DTXRecordingDidInvalidateDefactoEndTimestamp object:nil];
}

+ (BOOL)autosavesInPlace
{
	return YES;
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

- (void)makeWindowControllers
{
	[self addWindowController:[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"InstrumentsWindowController"]];
}

#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
- (DTXRecording*)_simulatedRecordingForRecording:(DTXRecording*)recording
{
	DTXRecording* rv = [[DTXRecording alloc] initWithEntity:recording.entity insertIntoManagedObjectContext:recording.managedObjectContext];
	
	[recording.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof NSPropertyDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		[rv setValue:[recording valueForKey:key] forKey:key];
	}];
	
	//Simulating a network recording, so start = end at the beginning.
	rv.endTimestamp = rv.startTimestamp;
	
	rv.rootSampleGroup = [[DTXSampleGroup alloc] initWithEntity:recording.rootSampleGroup.entity insertIntoManagedObjectContext:recording.managedObjectContext];
	[recording.rootSampleGroup.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof NSPropertyDescription * _Nonnull obj, BOOL * _Nonnull stop) {
		[rv.rootSampleGroup setValue:[recording.rootSampleGroup valueForKey:key] forKey:key];
	}];
	
	rv.threads = recording.threads;
	rv.minimumDefactoTimeInterval = 30.0;
	
	return rv;
}

static NSTimeInterval __DTXTimeIntervalStretcher(NSTimeInterval ti, BOOL invert)
{
	double t = 1.0 / 1.0;
	return ti * (invert ? 1.0 / t : t);
}

- (void)_simulatedRecordingTimerDidTick:(NSTimer*)timer
{
	NSDate* now = [NSDate date];
	NSTimeInterval passed = __DTXTimeIntervalStretcher([now timeIntervalSinceDate:_previousTickDate], NO);
	
	NSTimeInterval fromTI = __DTXTimeIntervalStretcher([_previousTickDate timeIntervalSinceDate:_timerStartDate], NO);
	NSDate* from = [_actualRecording.startTimestamp dateByAddingTimeInterval:fromTI];
	NSDate* to = [_actualRecording.startTimestamp dateByAddingTimeInterval:(fromTI + passed)];
	
	if([to compare:_actualRecording.defactoEndTimestamp] == NSOrderedDescending)
	{
		[timer invalidate];
		return;
	}
	
	NSFetchRequest* fr = [DTXSample fetchRequest];
	fr.predicate = [NSPredicate predicateWithFormat:@"NOT(sampleType IN %@) && timestamp >= %@ && timestamp < %@", @[@(DTXSampleTypeThreadPerformance), @(DTXSampleTypeGroup), @(DTXSampleTypeTag)], from, to];
	
	NSArray<__kindof DTXSample*>* samples = [_recording.managedObjectContext executeFetchRequest:fr error:NULL];
	
//	DTXSampleGroup* nextGroup = [[DTXSampleGroup alloc] initWithContext:_simulatedGroup.managedObjectContext];
//	nextGroup.name = @"group";
//	nextGroup.parentGroup = _simulatedGroup;
//	_simulatedGroup = nextGroup;
	
	[samples enumerateObjectsUsingBlock:^(__kindof DTXSample* _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.parentGroup = _simulatedGroup;
		
		if([obj isKindOfClass:[DTXNetworkSample class]])
		{
			DTXNetworkSample* networkSample = obj;
			int64_t code = networkSample.responseStatusCode;
			NSDate* end = networkSample.responseTimestamp;
			networkSample.responseStatusCode = 0;
			networkSample.responseTimestamp = nil;
			
			NSTimeInterval ti = __DTXTimeIntervalStretcher([end timeIntervalSinceDate:networkSample.timestamp], YES);
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ti * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				networkSample.responseStatusCode = code;
				networkSample.responseTimestamp = end;
			});
		}
	}];
	
	[_recording invalidateDefactoEndTimestamp];
	
	_previousTickDate = now;
}

#endif

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
	if(self.fileURL == nil)
	{
		return NO;
	}
	
#if ! DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
	self.documentType = DTXDocumentTypeOpenedFromDisk;
#else
	self.documentType = DTXDocumentTypeRecording;
#endif
	
	NSPersistentStoreDescription* description = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[self.fileURL URLByAppendingPathComponent:@"_dtx_recording.sqlite"]];
	NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[DTXDocument class]]]];
	
	_container = [NSPersistentContainer persistentContainerWithName:@"DTXInstruments" managedObjectModel:model];
	_container.persistentStoreDescriptions = @[description];
	
	[_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
		DTXRecording* recording = [_container.viewContext executeFetchRequest:[DTXRecording fetchRequest] error:NULL].firstObject;
		
#if ! DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
		_recording = recording;
#else
		_actualRecording = recording;
		_recording = [self _simulatedRecordingForRecording:_actualRecording];
		_simulatedGroup = _recording.rootSampleGroup;
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			_timerStartDate = _previousTickDate = [NSDate date];
			_simulatedRecordingTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(_simulatedRecordingTimerDidTick:) userInfo:nil repeats:YES];
			[[NSRunLoop mainRunLoop] addTimer:_simulatedRecordingTimer forMode:NSRunLoopCommonModes];
		});
#endif
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentDidLoadNotification object:self.windowControllers.firstObject];
		
		//The recording might not have been properly closed by the profiler for several reasons. If no close date, use the last sample as the close date.
		if(_recording.endTimestamp == nil)
		{
			_recording.endTimestamp = _recording.defactoEndTimestamp;
		}
		
		[self _prepareForRecording:_recording];
		
#if DTX_SIMULATE_NETWORK_RECORDING_FROM_FILE
#endif
	}];
	
	return YES;
}

- (void)_recordingDefactoEndTimestampDidChange:(NSNotification*)note
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DTXDocumentDefactoEndTimestampDidChangeNotification object:self];
}

- (void)readyForRecordingIfNeeded
{
	if(self.documentType == DTXDocumentTypeNone)
	{
		DTXRecordingTargetPickerViewController* vc = [self.windowControllers.firstObject.storyboard instantiateControllerWithIdentifier:@"DTXRecordingTargetChooser"];
		vc.delegate = self;
		[self.windowControllers.firstObject.window.contentViewController presentViewControllerAsSheet:vc];
		_recordingTargetPicker = vc;
	}
}

#pragma mark DTXRecordingTargetPickerViewControllerDelegate

- (void)recordingTargetPickerDidCancel:(DTXRecordingTargetPickerViewController*)picker
{
	[self.windowControllers.firstObject.window.contentViewController dismissViewController:picker];
	//If the user opened a new recording window but cancelled recording, close the new document.
	[self close];
}

@end
