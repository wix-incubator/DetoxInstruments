//
//  Swiftier.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 11/22/17.
//  Copyright © 2017 Wix. All rights reserved.
//

#ifndef Swiftier_h
#define Swiftier_h

#if defined(__cplusplus)
#else
#define auto __auto_type
#endif

#define defer_block_name_with_prefix(prefix, suffix) prefix ## suffix
#define defer_block_name(suffix) defer_block_name_with_prefix(defer_, suffix)
#define dtx_defer __strong void(^defer_block_name(__LINE__))(void) __attribute__((cleanup(defer_cleanup_block), unused)) = ^
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static void defer_cleanup_block(__strong void(^*block)(void)) {
	(*block)();
}
#pragma clang diagnostic pop

#ifdef __OBJC__
#ifdef __cplusplus
#import <Foundation/Foundation.h>
#else
@import Foundation;
#endif

@interface NSArray <ElementType> (PSPDFSafeCopy)
- (NSArray <ElementType> *)copy;
- (NSMutableArray <ElementType> *)mutableCopy;
@end

@interface NSSet <ElementType> (PSPDFSafeCopy)
- (NSSet <ElementType> *)copy;
- (NSMutableSet <ElementType> *)mutableCopy;
@end

@interface NSDictionary <KeyType, ValueType> (PSPDFSafeCopy)
- (NSDictionary <KeyType, ValueType> *)copy;
- (NSMutableDictionary <KeyType, ValueType> *)mutableCopy;
@end

@interface NSOrderedSet <ElementType> (PSPDFSafeCopy)
- (NSOrderedSet <ElementType> *)copy;
- (NSMutableOrderedSet <ElementType> *)mutableCopy;
@end

@interface NSHashTable <ElementType> (PSPDFSafeCopy)
- (NSHashTable <ElementType> *)copy;
@end

@interface NSMapTable <KeyType, ValueType> (PSPDFSafeCopy)
- (NSMapTable <KeyType, ValueType> *)copy;
@end

#endif

#endif /* Swiftier_pch */
