//
//  AHReporter.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "AHReporter.h"

@interface AHReporter ()
@property (nonatomic, copy) NSString *pmdFilePath;          //!< oclint输出文件
@end

@implementation AHReporter
- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (instancetype)initWithPmdFilePath:(NSString *)pmdFilePath {
    if (self = [self init]) {
        _pmdFilePath = pmdFilePath;
    }
    
    return self;
}

- (void)dealloc {
    
}

#pragma mark Public method
- (void)startReportWithClassArray:(NSArray<AHClassItem *> *)classArray
                       imageArray:(NSArray<AHImageItem *> *)imageArray {
    
    if (!self.pmdFilePath.length) {
        return;
    }
    
    NSError *error;
    NSString *pmdContent = [NSString stringWithContentsOfFile:self.pmdFilePath
                                                     encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"%@ 文件读入失败！", self.pmdFilePath);
    }
    
    NSMutableString *pmdString = [NSMutableString stringWithString:pmdContent];
    for (AHClassItem *className in classArray) {
        [self insertUnusedClass:className pmdContent:pmdString];
    }
    
    for (AHImageItem *imageItem in imageArray) {
        [self insertUnusedImage:imageItem pmdContent:pmdString];
    }
    
    BOOL succeed = [pmdString writeToFile:self.pmdFilePath
                               atomically:YES
                                 encoding:NSUTF8StringEncoding
                                    error:&error];
    if (succeed){
        NSLog(@"%@ 文件写入成功！", self.pmdFilePath);
    }
}

#pragma mark private method
- (void)insertUnusedClass:(AHClassItem *)classItem pmdContent:(NSMutableString *)pmdContent {
    NSString *xmlStr = [self getXmlStrWithFileName:classItem.filePath
                                              rule:@"未用到的类定义"
                                              desc:[NSString stringWithFormat:@"%@中定义的%@类未使用过！", classItem.filePath, classItem.className]];
    [self insertXml:xmlStr pmdContent:pmdContent];
}

- (void)insertUnusedImage:(AHImageItem *)imageItem pmdContent:(NSMutableString *)pmdContent {
    NSString *xmlStr = [self getXmlStrWithFileName:imageItem.imagePath
                                              rule:@"未用到的图片资源"
                                              desc:[NSString stringWithFormat:@"%@图片在程序中未使用过！", imageItem.imageName]];
    
    [self insertXml:xmlStr pmdContent:pmdContent];
}

- (void)insertXml:(NSString *)itemXmlStr pmdContent:(NSMutableString *)pmdContent {
    if (itemXmlStr.length) {
        NSRange endRange = [pmdContent rangeOfString:@"</pmd>"];
        if (endRange.location>0  && endRange.length>0) {
            [pmdContent insertString:itemXmlStr atIndex:endRange.location];
        }
    }
}

- (NSString *)getXmlStrWithFileName:(NSString *)fileName rule:(NSString *)ruleStr desc:(NSString *)desc {
    NSString *xmlFormatStr = [NSString stringWithFormat:@"\n<file name=\"%@\">\n<violation begincolumn=\"1\" endcolumn=\"0\" beginline=\"0\" endline=\"0\" priority=\"3\" rule=\"%@\" ruleset=\"AutoHome\" >\n%@\n</violation>\n</file>\n", fileName, ruleStr, desc];
    
    return xmlFormatStr;
}

@end
