//
//  AppUtilities.m
//  VTARewards
//
//  Created by Akshay on 9/7/15.
//  Copyright (c) 2015 akshay. All rights reserved.
//

#import "AppUtilities.h"

@implementation AppUtilities

+ (void)saveDictionaryToFile:(NSDictionary *)dict{
    NSError *error;
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"trip.txt"];
    
    NSString *stringToWrite = [[NSString alloc]init];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        stringToWrite = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    }
    
    stringToWrite = [stringToWrite stringByAppendingString:[NSString stringWithFormat:@"%@\n",[[self class] toJSON:dict]]];
    BOOL status = [stringToWrite writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (status) {
        NSLog(@"Data saved to %@",filePath);
    }else{
        NSLog(@"error writing %@",error);
    }
}

+ (NSString *)toJSON:(id)object{
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


@end
