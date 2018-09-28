//
//  AHImageItem.h
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/22.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EImageFolderType) {
    kIFT_Source = 0,
    kIFT_Bundle,
    kIFT_Imageset
};

@interface AHImageItem : NSObject
@property (nonatomic, copy) NSString *imageName;                //!< 图片名称
@property (nonatomic, copy) NSString *imagePath;                //!< 图片路径
@property (nonatomic, assign) BOOL isUsed;                      //!< 是否使用过
@property (nonatomic, assign) EImageFolderType floderType;      //!< 图片所在文件夹类型
@end
