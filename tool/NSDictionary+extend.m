//
//  NSDictionary+extend.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/23.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "NSDictionary+extend.h"

@implementation NSDictionary (extend)
- (NSString *)ah_toJsonString {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if ([jsonData length] > 0 && error == nil){
        return [[NSString alloc] initWithData:jsonData
                                     encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

@end
