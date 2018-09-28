//
//  AHUnusedImageChecker.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHBaseChecker.h"
#import "AHImageItem.h"

@interface AHUnusedImageChecker : AHBaseChecker

- (NSArray<AHImageItem *> *)getUnusedImageInProjectPath:(NSString *)projectPath;
@end
