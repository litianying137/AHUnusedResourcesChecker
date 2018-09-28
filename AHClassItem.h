//
//  AHClassItem.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/22.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AHClassItem : NSObject
@property (nonatomic, copy) NSString *className;        //!< 类名称
@property (nonatomic, copy) NSString *filePath;         //!< 类所在文件路径
@property (nonatomic, assign) NSInteger lineNumber;     //!< 类声明所在行号
@property (nonatomic, assign) BOOL isUsed;              //!< 是否使用过
@end
