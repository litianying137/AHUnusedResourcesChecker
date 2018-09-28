//
//  main.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <getopt.h>
#import "AHApplication.h"

int main(int argc, const char *argv[]) {
    int result = -1;
    @autoreleasepool {
        AHApplication *app = [[AHApplication alloc] init];
        result = (int)[app launchCheckerWithArgv:argv argc:argc];
    }
    
    return result;
}
