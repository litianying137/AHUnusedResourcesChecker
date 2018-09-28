//
//  AHReporter.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHClassItem.h"
#import "AHImageItem.h"

@interface AHReporter : NSObject


/**
 初始化函数

 @param pmdFilePath oclint的pmd文件路径
 @return 本类实例
 */
- (instancetype)initWithPmdFilePath:(NSString *)pmdFilePath;

/**
 输出检测报告

 @param classArray 无用类数组
 @param imageArray 无用图片数组
 */
- (void)startReportWithClassArray:(NSArray<AHClassItem *> *)classArray
                       imageArray:(NSArray<AHImageItem *> *)imageArray;

@end
