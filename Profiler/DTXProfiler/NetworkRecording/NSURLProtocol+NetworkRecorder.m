//
//  NSURLProtocol+NetworkRecorder.m
//  DTXProfiler
//
//  Created by Leo Natan (Wix) on 2/24/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#import "NSURLProtocol+NetworkRecorder.h"
#import <objc/runtime.h>

thread_local BOOL _protocolLoading;

static NSArray *__DTXClassGetSubclasses(Class parentClass, SEL sel)
{
	int numClasses = objc_getClassList(NULL, 0);
	__block Class* classes = NULL;
	
	classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
	dtx_defer {
		free(classes);
	};
	numClasses = objc_getClassList(classes, numClasses);
	
	NSMutableArray *result = [NSMutableArray array];
	for (NSInteger i = 0; i < numClasses; i++)
	{
		Class superClass = classes[i];
		do
		{
			superClass = class_getSuperclass(superClass);
		}
		while(superClass && superClass != parentClass);
		
		if (superClass == nil)
		{
			continue;
		}
		
		unsigned int numMethods = 0;
		__block Method* methods = class_copyMethodList(classes[i], &numMethods);
		dtx_defer {
			free(methods);
		};

		BOOL found = NO;
		for(NSInteger j = 0; j < numMethods; j++)
		{
			if(sel_isEqual(method_getName(methods[j]), sel) == YES)
			{
				found = YES;
				break;
			}
		}

		if(found == NO)
		{
			continue;
		}
		
		[result addObject:classes[i]];
	}
	
	return result;
}

@implementation NSURLProtocol (NetworkRecorder)

+(void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SEL sel = @selector(startLoading);
		
		NSArray<Class>* subclasses = __DTXClassGetSubclasses(NSURLProtocol.class, sel);
		
		[subclasses enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			Method m = class_getInstanceMethod(obj, sel);
			void (*orig_imp)(id, SEL) = (void(*)(id, SEL))method_getImplementation(m);
			method_setImplementation(m, imp_implementationWithBlock(^ (id _self) {
				_protocolLoading = YES;
				orig_imp(_self, sel);
				_protocolLoading = NO;
			}));
		}];
	});
}

@end
