//
//  AHUnusedClassChecker.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHBaseChecker.h"
#import "AHClassItem.h"

@interface AHUnusedClassChecker : AHBaseChecker


/**
 获取无用类

 @param projectPath project文件路径
 @return 未使用的类列表
 */
- (NSArray<AHClassItem *> *)getUnusedClassWithProjectPath:(NSString *)projectPath;
@end
