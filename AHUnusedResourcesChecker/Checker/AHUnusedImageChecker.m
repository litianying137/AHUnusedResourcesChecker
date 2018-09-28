//
//  AHUnusedImageChecker.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "AHUnusedImageChecker.h"

@interface AHUnusedImageChecker ()
@property (nonatomic, strong) NSMutableArray *allSourceFileArray;               //!< 所有实现文件路径 包括m、mm、xib、storyboard
@property (nonatomic, strong) NSMutableDictionary *allImageDic;                 //!< 工程中所有的图片资源文件
@end

@implementation AHUnusedImageChecker
- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)dealloc {
    
}

#pragma mark Public method
- (NSArray<AHImageItem *> *)getUnusedImageInProjectPath:(NSString *)projectPath {
    self.pbxprojPath = [projectPath stringByAppendingPathComponent:@"project.pbxproj"];
    self.projectPath = projectPath;
    
    //2.get objects & root object uuid.
    NSDictionary *pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:self.pbxprojPath];
    NSDictionary *objects = pbxprojDic[@"objects"];
    NSString* rootObjectUuid = pbxprojDic[@"rootObject"];
    
    //3.get main group dictionary.
    NSDictionary* projectObject = objects[rootObjectUuid];
    NSString* mainGroupUuid = projectObject[@"mainGroup"];
    NSDictionary* mainGroupDic = objects[mainGroupUuid];
    
    NSString *projectDir = [self.projectPath stringByDeletingLastPathComponent];
    
    // 遍历工程文件 产出self.allImageDic self.allSourceFileArray
    [self traversalFileWithDir:projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid pbxprojDic:pbxprojDic];
//    NSLog(@"All Image Source = %@", self.allImageDic.allKeys);
    
    // 在实现文件中遍历 查看哪些图片使用过
    for (NSString *impFilePath in self.allSourceFileArray) {
        [self searchImageInSourceFile:impFilePath];
    }
    
    return [self getUnusedArray];
}

#pragma mark private method
- (NSArray<AHImageItem *> *)getUnusedArray {
    NSMutableArray *unusedArray = [NSMutableArray arrayWithCapacity:10];

    for (NSString *imageName in self.allImageDic.allKeys) {
        
        AHImageItem *item = self.allImageDic[imageName];
        if (!item.isUsed) {
            [unusedArray addObject:item];
            NSLog(@"Unused image name = %@", item.imagePath);
        }
    }
    
    return unusedArray;
}

- (void)searchImageInSourceFile:(NSString *)impFilePath {
//    NSLog(@"impFilePath = %@", impFilePath);
    NSString *contentFile = [NSString stringWithContentsOfFile:impFilePath encoding:NSUTF8StringEncoding error:nil];
    if (contentFile.length == 0) {
        return;
    }
    
    for (NSString *imageName in self.allImageDic.allKeys) {
        AHImageItem *imageItem = self.allImageDic[imageName];
        if (!imageItem.isUsed) {
//            NSLog(@"current image = %@", imageName);
            imageItem.isUsed = [self isUsedImageName:imageName contengFile:contentFile];
//            NSLog(@"%@ imageItem.isUsed %@", imageName, imageItem.isUsed?@"YES":@"NO");
        }
    }
}

- (BOOL)isUsedImageName:(NSString *)imageName contengFile:(NSString *)contentString {
    NSString *targetStr = [NSString stringWithFormat:@"@\"%@\"", imageName];
    NSRange rang = [contentString rangeOfString:targetStr];
    
    return rang.length;
}

- (void)traversalFileWithDir:(NSString *)dir mainGroupDic:(NSDictionary *)mainGroupDic uuid:(NSString*)uuid pbxprojDic:(NSDictionary *)pbxprojDic {
    NSDictionary *objects = pbxprojDic[@"objects"];
    NSArray *childrenArray = mainGroupDic[@"children"];
    NSString *path = mainGroupDic[@"path"];
    NSString *sourceTree = mainGroupDic[@"sourceTree"];
    
    if(path.length > 0) {
        if([sourceTree isEqualToString:@"<group>"]){
            dir = [dir stringByAppendingPathComponent:path];
        }
        else if([sourceTree isEqualToString:@"SOURCE_ROOT"]){
            dir = [self.projectPath stringByAppendingPathComponent:path];
        }
    }
    
    if(childrenArray.count == 0) {
        NSString *pathExtension = dir.pathExtension;
        // 要在头文件中查找类被继承的情况 在实现文件中查找类调用情况
        if([pathExtension isEqualToString:@"png"] ||
           [pathExtension isEqualToString:@"gif"] ||
           [pathExtension isEqualToString:@"jpg"]) {
            
            [self addItemImageWithPath:path floderType:kIFT_Source];
        } else if ([pathExtension isEqualToString:@"xcassets"] ||
                   [pathExtension isEqualToString:@"bundle"]) {
            
            [self searchImageInPath:dir container:self.allImageDic];
        } else if ([pathExtension isEqualToString:@"h"] || // 有些图片名称还在头文件中define过...
                   [pathExtension isEqualToString:@"m"] ||
                   [pathExtension isEqualToString:@"mm"] ||
                   [pathExtension isEqualToString:@"xib"] ||
                   [pathExtension isEqualToString:@"storyboard"]) {
            // 获取实现文件列表
            [self.allSourceFileArray addObject:dir];
        }
    } else {
        for (NSString *key in childrenArray) {
            NSDictionary *childrenDic = objects[key];
            [self traversalFileWithDir:dir mainGroupDic:childrenDic uuid:key pbxprojDic:pbxprojDic];
        }
    }
}

- (void)searchImageInPath:(NSString *)path container:(NSMutableDictionary *)containerDic {
//    NSLog(@"path = %@", path);
    NSFileManager *fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];
    
    if (isExist) {
        if (isDir) {
            NSArray *dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
            NSString *subPath = nil;
            for (NSString * str in dirArray) {
                if ([str.pathExtension isEqualToString:@"imageset"]) { //如果是imageset 就不获取真实的文件名称了
                    [self addItemImageWithPath:[path stringByAppendingPathComponent:str] floderType:kIFT_Imageset];
                } else {
                    subPath = [path stringByAppendingPathComponent:str];
                    [self searchImageInPath:subPath container:containerDic];
                }
            }
        } else {
            if ([path.pathExtension isEqualToString:@"png"] ||
                [path.pathExtension isEqualToString:@"jpg"] ||
                [path.pathExtension isEqualToString:@"gif"]) {
                
                [self addItemImageWithPath:path floderType:kIFT_Bundle];
            }
        }
    } else {
        NSLog(@"this path is not exist!");
    }
}

- (void)addItemImageWithPath:(NSString *)imagePath floderType:(EImageFolderType)floderType {
    NSString *fileName = [self dumpRealName:[imagePath lastPathComponent]];
    if (![self.allImageDic.allKeys containsObject:fileName]) {
        AHImageItem *item = [[AHImageItem alloc] init];
        item.imageName = fileName;
        item.imagePath = imagePath;
        item.floderType = floderType;
        [self.allImageDic setObject:item forKey:fileName];
    }
}

- (NSString *)dumpRealName:(NSString *)fileName {
    NSString *realName = fileName;
    NSRange range = [fileName rangeOfString:@"@"];
    if (range.length) {
        realName = [fileName substringWithRange:NSMakeRange(0, range.location)];
    } else {
        range = [fileName rangeOfString:@"."];
        if (range.length) {
            realName = [fileName substringWithRange:NSMakeRange(0, range.location)];
        }
    }
    
    return realName;
}

#pragma mark Geter&Setter method
- (NSMutableArray *)allSourceFileArray {
    if (!_allSourceFileArray) {
        _allSourceFileArray = [NSMutableArray arrayWithCapacity:100];
    }
    
    return _allSourceFileArray;
}

- (NSMutableDictionary *)allImageDic {
    if (!_allImageDic) {
        _allImageDic = [NSMutableDictionary dictionaryWithCapacity:100];
    }
    
    return _allImageDic;
}
@end
