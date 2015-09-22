//
//  ViewController.m
//  VTARewards
//
//  Created by Akshay on 6/13/15.
//  Copyright (c) 2015 akshay. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "LocationTracker.h"
#import <KontaktSDK/KontaktSDK.h>

@interface ViewController ()<KTKLocationManagerDelegate>

@property KTKLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[KTKLocationManager alloc]init];
    self.locationManager.delegate = self;

    if ([KTKLocationManager canMonitorBeacons]){
        KTKRegion *region =[[KTKRegion alloc] init];
        region.uuid = @"f7826da6-4fa2-4e98-8024-bc5b71e0893e";
        [self.locationManager setRegions:@[region]];
        [self.locationManager startMonitoringBeacons];
        [self.statusLabel setText:@"Searching for beacons..."];
    }else{
        NSLog(@"cannot Monitor Beacons");
    }
}

- (void)locationManager:(KTKLocationManager *)locationManager didChangeState:(KTKLocationManagerState)state withError:(NSError *)error
{
    if (state == KTKLocationManagerStateFailed)
    {
        NSLog(@"Something went wrong with your Location Services settings. Check OS settings.");
    }
}

#pragma mark - KTKLocationManagerDelegate
-(void)locationManager:(KTKLocationManager *)locationManager didEnterRegion:(KTKRegion *)region
{
    NSLog(@"You are near a beacon!");
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    [notification setFireDate:[NSDate date]];
    [notification setAlertBody:@"You are near a beacon!"];
    [notification setAlertTitle:@"Beacon around"];
    [notification setAlertAction:@"Hmmm, OK!"];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    [self.statusLabel setText:@"Beacon found. Tracking location..."];
    
    [[LocationTracker sharedLocationTracker] startLocationUpdates];
}

-(void)locationManager:(KTKLocationManager *)locationManager didExitRegion:(KTKRegion *)region
{
    NSLog(@"You are leaving a beacon region!");
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    [notification setFireDate:[NSDate date]];
    [notification setAlertBody:@"You are leaving a beacon region!"];
    [notification setAlertTitle:@"Beacon away"];
    [notification setAlertAction:@"Hmmm, OK!"];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    [self.statusLabel setText:@"Beacon region exited. Captured waypoints"];
    [[LocationTracker sharedLocationTracker] stopUpdatingLocation];
}

- (void)locationManager:(KTKLocationManager *)locationManager didRangeBeacons:(NSArray *)beacons
{
    NSLog(@"Ranged beacons count: %lu", (unsigned long)[beacons count]);
    [beacons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLBeacon* beacon = (CLBeacon*)obj;
        NSLog(@"%d - major %d minor %d strength %d accuracy %f",idx,[beacon.major intValue],[beacon.minor intValue],beacon.rssi,beacon.accuracy);
    }];
}


/*
- (IBAction)startStopUpdates:(id)sender {
    UISwitch *startStopSwitch = (UISwitch *)sender;
    if (startStopSwitch.isOn) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            [self.locationManager startUpdatingLocation];
            
            //clear all data before capturing new
            self.start = nil;
            self.stop = nil;
            self.waypoints = nil;
            self.tripData = nil;
        }
    }else{
        [self.locationManager stopUpdatingLocation];

        //remove last object from waypoints because it is already present in stop location
        [self.waypoints removeLastObject];
        if (self.tripData == nil) {
            self.tripData = [[NSMutableDictionary alloc]init];
        }
        [self.tripData setObject:self.start forKey:@"start"];
        [self.tripData setObject:self.waypoints forKey:@"waypoints"];
        [self.tripData setObject:self.stop forKey:@"stop"];
        
        //saving to documents directory
        [self saveToFile];
        NSLog(@"self.tripData %@",self.tripData);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location data"
                                                                       message:[NSString stringWithFormat:@"%@",self.tripData]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {}];
        [alert addAction:action];
        [alert .view setFrame:[[UIScreen mainScreen] applicationFrame]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        if ([self.startStopSwitch isOn]) {
            [self.locationManager startUpdatingLocation];
        }
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
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"error %@",error);
}

#pragma mark Helper Methods

- (void)saveToFile{
    NSError *error;
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"trip.txt"];
    
    NSString *stringToWrite = [[NSString alloc]init];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        stringToWrite = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    }
    
    stringToWrite = [stringToWrite stringByAppendingString:[NSString stringWithFormat:@"%@\n",[self toJSON:self.tripData]]];
    BOOL status = [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (status) {
        NSLog(@"Data saved to %@",filePath);
    }else{
        NSLog(@"error writing %@",error);
    }
}

- (NSString *)toJSON:(id)object{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *jsonString = nil;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
*/
@end
