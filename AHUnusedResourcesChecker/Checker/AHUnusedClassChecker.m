//
//  AHUnusedClassChecker.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "AHUnusedClassChecker.h"
#import "NSDictionary+extend.h"

@interface AHUnusedClassChecker()
@property (nonatomic, strong) NSMutableDictionary *allClassDic;             //!< 所有类集合
@property (nonatomic, strong) NSMutableDictionary *unusedClassDic;          //!< 未使用类集合
@property (nonatomic, strong) NSMutableArray *allSourceFileArray;           //!< 所有实现文件路径
@end

@implementation AHUnusedClassChecker
- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)dealloc {
    
}

#pragma mark Public method
- (NSArray<AHClassItem *> *)getUnusedClassWithProjectPath:(NSString *)projectPath {
    self.pbxprojPath = [projectPath stringByAppendingPathComponent:@"project.pbxproj"];
    self.projectPath = projectPath;
    
    //2.get objects & root object uuid.
    NSDictionary *pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:self.pbxprojPath];
//    NSLog(@"pbxprojDic = %@", [pbxprojDic ah_toJsonString]);
    NSDictionary *objects = pbxprojDic[@"objects"];
    NSString *rootObjectUuid = pbxprojDic[@"rootObject"];
    
    //3.get main group dictionary.
    NSDictionary *projectObject = objects[rootObjectUuid];
    NSString *mainGroupUuid = projectObject[@"mainGroup"];
    NSDictionary *mainGroupDic = objects[mainGroupUuid];
    
    NSString *projectDir = [self.projectPath stringByDeletingLastPathComponent];
    
    // 获取所有源码文件目录数组
    [self searchAllImpFileWithDir:projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid pbxprojDic:pbxprojDic];
    
    // 获取所有imp文件中定义的类
    for (NSString *impFilePath in self.allSourceFileArray) {
        [self dumpClassInImpFile:impFilePath];
    }
    
    // 扫描头文件与实现文件 来判断哪些类被使用过 （在每个源码文件中查找每一个类名称） 1，[ClassName xxx] 2,@interface SubClass : ClassName
    for (NSString *impFilePath in self.allSourceFileArray) {
        [self traversalUsedClass:impFilePath];
    }
    
    return [self getUnusedArray];
}

#pragma mark private method
- (NSArray *)getUnusedArray {
    NSMutableArray *unusedArray = [NSMutableArray arrayWithCapacity:10];
    NSArray *allClassNameAry = self.allClassDic.allKeys;
    for (NSString *className in allClassNameAry) {
        
        AHClassItem *classItem = self.allClassDic[className];
        if (!classItem.isUsed) {
            [unusedArray addObject:classItem];
            NSLog(@"Unused class name = %@", classItem.className);
        }
    }
    
    //TODO: 可以续匹配出无用import
    
    return unusedArray;
}

- (void)traversalUsedClass:(NSString *)impFilePath {
    NSString *contentFile = [NSString stringWithContentsOfFile:impFilePath encoding:NSUTF8StringEncoding error:nil];
    if(contentFile.length == 0)
        return;
    
    NSArray *allClassNameAry = self.allClassDic.allKeys;
    for (NSString *className in allClassNameAry) {
        if ([className isEqualToString:@"AHAShrinkScreenVideoPlayCompletedItemView"]) {
            if ([impFilePath hasSuffix:@"AHAShrinkScreenVideoPlayCompletedView.m"]) {
                int a = 0;a ++;
            }
        }

        AHClassItem *classItem = self.allClassDic[className];
        if (classItem.isUsed) {
            continue;
        }
        
        // 匹配类被调用 [ClassName ...]
        NSString *regularStr = [NSString stringWithFormat:@"\\[[ ]*%@[ ]+", className];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
        NSArray *matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
        if (matches.count > 0) {
            classItem.isUsed = YES;
        }
        
        // 匹配类被继承 @interface SubClass : ClassName <...>
        regularStr = [NSString stringWithFormat:@"@interface[ ]*[\n]*[A-z, 0-9]+[ ]*[\n]*:[ ]*[\n]*%@[ ]*", className];
        regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
        matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
        
        if (matches.count > 0) {
            classItem.isUsed = YES;
        }
        
        // 匹配类名称字面量 @"ClassName"
        regularStr = [NSString stringWithFormat:@"@\"%@\"", className];
        regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
        matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
        if (matches.count > 0) {
            classItem.isUsed = YES;
        }
    }
}

- (void)dumpClassInImpFile:(NSString *)impFilePath {
    // 查找@implementation声明的类实现 所以排除头文件
    if ([impFilePath.pathExtension isEqualToString:@"h"]) {
        return;
    }
    
    NSString *contentFile = [NSString stringWithContentsOfFile:impFilePath encoding:NSUTF8StringEncoding error:nil];
    if (contentFile.length == 0) {
        return;
    }
    
    //查找类定义
    NSString *regularStr = @"@implementation[ ]+[A-z, 0-9]+[ ]*\n";//匹配implementation语句 自动去除category
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
    NSArray *matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
    for (NSTextCheckingResult *match in matches) {
        
        NSRange range = [match range];
        NSString *className = [self getClassNameWithContent:contentFile impRang:range];
        if (className.length) {
            AHClassItem *itemClass = [[AHClassItem alloc] init];
            itemClass.className = className;
            itemClass.filePath = impFilePath;
            itemClass.isUsed = NO;
            [self.allClassDic setObject:itemClass forKey:className];
        }
    }
}

- (NSString *)getClassNameWithContent:(NSString *)contentFile impRang:(NSRange)rang {
    NSString *className = nil;
    NSString *totalLineStr = [contentFile substringWithRange:rang];
    NSArray *tmpAry = [totalLineStr componentsSeparatedByString:@" "];
    for (NSInteger i=tmpAry.count-1; i>=0; i--) {
        
        NSString *tmpStr = tmpAry[i];
        className = (tmpStr.length && (![tmpStr isEqualToString:@"\n"])) ? tmpAry[i] : @"";
        if (className.length)
            break;
    }
    className = [self removeSpaceAndNewline:className];
    
    return className;
}

- (NSString *)removeSpaceAndNewline:(NSString *)str {
    NSString *temp = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return temp;
}

- (void)searchAllImpFileWithDir:(NSString *)dir mainGroupDic:(NSDictionary *)mainGroupDic uuid:(NSString*)uuid pbxprojDic:(NSDictionary *)pbxprojDic{
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
    
    // 说明是文件 不是路径了
    if(childrenArray.count == 0) {
        NSString *pathExtension = dir.pathExtension;
        // 要在头文件中查找类被继承的情况 在实现文件中查找类调用情况
        if([pathExtension isEqualToString:@"m"] || [pathExtension isEqualToString:@"mm"] || [pathExtension isEqualToString:@"h"]) {
            if (![self.allSourceFileArray containsObject:dir]) {
                [self.allSourceFileArray addObject:dir];
            }
        }
    } else {
        for (NSString *key in childrenArray) {
            NSDictionary *childrenDic = objects[key];
            [self searchAllImpFileWithDir:dir mainGroupDic:childrenDic uuid:key pbxprojDic:pbxprojDic];
        }
    }
}

#pragma mark Getter & Setter
- (NSMutableDictionary *)allClassDic {
    if (!_allClassDic) {
        _allClassDic = [[NSMutableDictionary alloc] initWithCapacity:100];
    }
    
    return _allClassDic;
}

- (NSMutableDictionary *)unusedClassDic {
    if (!_unusedClassDic) {
        _unusedClassDic = [[NSMutableDictionary alloc] initWithCapacity:100];
    }
    
    return _unusedClassDic;
}

- (NSMutableArray *)allSourceFileArray {
    if (!_allSourceFileArray) {
        _allSourceFileArray = [NSMutableArray arrayWithCapacity:100];
    }
    
    return _allSourceFileArray;
}

@end
