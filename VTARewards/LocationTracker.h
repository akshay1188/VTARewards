//
//  LocationTracker.h
//  VTARewards
//
//  Created by Akshay on 9/7/15.
//  Copyright (c) 2015 akshay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationTracker : NSObject

+ (id)sharedLocationTracker;
- (void)startLocationUpdates;
- (void)stopUpdatingLocation;

@end
