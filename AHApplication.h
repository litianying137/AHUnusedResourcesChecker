//
//  AHApplication.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AHApplication : NSObject


/**
 开始检查逻辑·
 
 @param argv 命令行入参个数
 @param argc 命令行入参数组
 @return 保留
 */
- (NSInteger)launchCheckerWithArgv:(char * const *)argv argc:(int)argc;

@end
