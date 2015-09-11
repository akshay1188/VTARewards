//
//  LocationTracker.m
//  VTARewards
//
//  Created by Akshay on 9/7/15.
//  Copyright (c) 2015 akshay. All rights reserved.
//

#import "LocationTracker.h"
#import <CoreLocation/CoreLocation.h>
#import "AppUtilities.h"
#import <UIKit/UIKit.h>

static LocationTracker *locationTracker = nil;

@interface LocationTracker()<CLLocationManagerDelegate>{

}
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *waypoints;
@property (nonatomic, strong) NSDictionary *start;
@property (nonatomic, strong) NSDictionary *stop;
@property (nonatomic, strong) NSMutableDictionary *tripData;

@end

@implementation LocationTracker

+ (id)sharedLocationTracker{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        locationTracker = [[self alloc]init];
    });
    return locationTracker;
}

- (id)init{
    if (self = [super init]) {
        if (self.locationManager == nil) {
            self.locationManager = [[CLLocationManager alloc]init];
            self.locationManager.delegate = self;
            [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
            [self.locationManager setDistanceFilter:20.0f];
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                [self.locationManager requestAlwaysAuthorization];
            }
        }
    }
    return self;
}

- (void)startLocationUpdates{
    //TODO:
    //Add background location tracking
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
        
        //clear all data before capturing new
        self.start = nil;
        self.stop = nil;
        self.waypoints = nil;
        self.tripData = nil;
    }
}

- (void)stopUpdatingLocation{
    //TODO:
    //Add background location tracking
    [self.locationManager stopUpdatingLocation];
    
    //remove last object from waypoints because it is already present in stop location
    if (self.waypoints != nil) {
        [self.waypoints removeLastObject];
    }

    if (self.tripData == nil) {
        self.tripData = [[NSMutableDictionary alloc]init];
    }
    if (self.start!=nil) {
        [self.tripData setObject:self.start forKey:@"start"];
    }
    if (self.waypoints!=nil) {
        [self.tripData setObject:self.waypoints forKey:@"waypoints"];
    }
    if (self.stop!=nil) {
        [self.tripData setObject:self.stop forKey:@"stop"];
    }
    
    //saving to documents directory
    [AppUtilities saveDictionaryToFile:self.tripData];
    NSLog(@"self.tripData %@",self.tripData);
}

#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
//        [self.locationManager startUpdatingLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSLog(@"locations %@",locations);
    if (self.waypoints == nil) {
        self.waypoints = [[NSMutableArray alloc]init];
    }
    
    //form dictionary from the first location object
    CLLocation *location = [locations objectAtIndex:0];
    
    NSNumber *timestamp = [NSNumber numberWithDouble:[location.timestamp timeIntervalSince1970]*1000];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:0];
    
    NSDictionary *locationDict = @{@"lat":[NSNumber numberWithDouble:location.coordinate.latitude],
                                   @"lng":[NSNumber numberWithDouble:location.coordinate.longitude],
                                   @"timestamp":[formatter  stringFromNumber:timestamp]};
    
    if (self.start == nil) {
        //capture the start location
        self.start = locationDict;
    }else{
        //capture waypoints
        [self.waypoints addObject:locationDict];
    }
    //every recent location is overwritten to the stop location
    self.stop = locationDict;
//    [self stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"error %@",error);
}


@end
