//
//  DTXSignpostProtocol.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 7/4/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#ifndef DTXSignpostProtocol_h
#define DTXSignpostProtocol_h

@protocol DTXSignpost <NSObject>

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSDate* timestamp;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval minDuration;
@property (nonatomic, readonly) NSTimeInterval avgDuration;
@property (nonatomic, readonly) NSTimeInterval stddevDuration;
@property (nonatomic, readonly) NSTimeInterval maxDuration;

@end

#endif /* DTXSignpostProtocol_h */
