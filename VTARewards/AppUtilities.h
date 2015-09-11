//
//  AppUtilities.h
//  VTARewards
//
//  Created by Akshay on 9/7/15.
//  Copyright (c) 2015 akshay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppUtilities : NSObject
+ (void)saveDictionaryToFile:(NSDictionary *)dict;
+ (NSString *)toJSON:(id)object;
@end
