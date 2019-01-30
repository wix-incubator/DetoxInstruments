//
//  DTXMeasurements.h
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 1/23/19.
//  Copyright © 2019 Wix. All rights reserved.
//

#ifndef DTXMeasurements_h
#define DTXMeasurements_h

#define DTXStartTimeMeasurment() CFTimeInterval ___startTime = CACurrentMediaTime();

#define DTXEndTimeMeasurment(action) CFTimeInterval ___elapsedTime = CACurrentMediaTime() - ___startTime; \
dtx_log_info(@"%@ took %f seconds to " action, self.class, ___elapsedTime);

#endif /* DTXMeasurements_h */
