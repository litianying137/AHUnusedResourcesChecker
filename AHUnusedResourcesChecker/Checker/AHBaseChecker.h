//
//  AHBaseChecker.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AHBaseChecker : NSObject
@property (nonatomic, copy) NSString *projectPath;                          //!< 被检查工程路径，包含project文件的目录
@property (nonatomic, copy) NSString *pbxprojPath;                          //!< 工程文件路径

@end
