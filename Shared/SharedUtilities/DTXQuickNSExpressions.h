//
//  DTXQuickNSExpressions.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/16/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#ifndef DTXQuickNSExpressions_h
#define DTXQuickNSExpressions_h

#import <Foundation/Foundation.h>

static inline NSExpression* DTXKeyPathExpression(NSString* keyPath)
{
	return [NSExpression expressionForKeyPath:keyPath];
}

static inline NSExpression* DTXFunctionExpression(NSString* function, NSArray* arguments)
{
	return [NSExpression expressionForFunction:function arguments:arguments];
}

#endif /* DTXQuickNSExpressions_h */
