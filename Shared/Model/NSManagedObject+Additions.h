//
//  NSManagedObject+Additions.h
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 21/05/2017.
//  Copyright © 2017-2019 Wix. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString* const DTXNSManagedObjectDictionaryRepresentationJSONCallingKey;
extern NSString* const DTXNSManagedObjectDictionaryRepresentationProperyListCallingKey;

extern id(^DTXNSManagedObjectDictionaryRepresentationJSONTransformer)(NSPropertyDescription* obj, id val);
extern id(^DTXNSManagedObjectDictionaryRepresentationPropertyListTransformer)(NSPropertyDescription* obj, id val);

NSMutableDictionary* DTXNSManagedObjectDictionaryRepresentation(id self, NSEntityDescription* entity, NSArray<NSString*>* filteredKeys, id(^transformer)(NSPropertyDescription* obj, id val), NSString* callingKey, BOOL includeMetadata, BOOL cleanIfNeeded);

@interface NSManagedObject (Additions)

@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationForJSON;
@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationForPropertyList;
@property (nonatomic, readonly) NSDictionary<NSString*, id>* dictionaryRepresentationOfChangedValuesForPropertyList;

@property (nonatomic, readonly) NSDictionary<NSString*, id>* cleanDictionaryRepresentationForJSON;
@property (nonatomic, readonly) NSDictionary<NSString*, id>* cleanDictionaryRepresentationForPropertyList;

- (instancetype)initWithPropertyListDictionaryRepresentation:(NSDictionary*)propertyListDictionaryRepresentation context:(NSManagedObjectContext *)moc;
- (void)updateWithPropertyListDictionaryRepresentation:(NSDictionary *)propertyListDictionaryRepresentation;

@end
