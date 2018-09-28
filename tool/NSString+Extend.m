//
//  NSString+Extend.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/23.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "NSString+Extend.h"

@implementation NSString (Extend)

- (id)ah_jsonDecode {
    if(![self isKindOfClass:[NSString class]]) return nil;
    NSData *data =  [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error=nil;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers error:&error];
}

@end
