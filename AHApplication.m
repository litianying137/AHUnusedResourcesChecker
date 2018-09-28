//
//  AHApplication.m
//  AHUnusedResourcesChecker
//
//  Created by 李田迎 on 2017/8/18.
//  Copyright © 2017年 李田迎. All rights reserved.
//

#import "AHApplication.h"
#import "AHUnusedClassChecker.h"
#import "AHUnusedImageChecker.h"
#import "AHReporter.h"
#import <getopt.h>

static void Printf(NSString* fmt, ...)
{
    va_list ap;
    va_start (ap, fmt);
    NSString *output = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end (ap);
    printf("%s", [output UTF8String]);
}

@interface AHApplication()
@property (nonatomic, copy) NSString *projectPath;                          //!< 被检查工程路径，包含project文件的目录
@property (nonatomic, copy) NSString *pbxprojPath;                          //!< 工程文件路径
@property (nonatomic, copy) NSString *origPmdFilePath;                      //!< oclint输出报告文件
@property (nonatomic, strong) AHUnusedClassChecker *unusedClassChecker;     //!< 未使用类检查
@property (nonatomic, strong) AHUnusedImageChecker *unusedImageChecker;     //!< 未使用图片检查
@property (nonatomic, strong) AHReporter *reporter;                         //!< 报告
@end

@implementation AHApplication
- (instancetype)init {
    if (self = [super init]) {
    }
    
    return self;
}

- (void)dealloc {
    
}

- (NSInteger)launchCheckerWithArgv:(char * const *)argv argc:(int)argc {
    
    static struct option options[] = {
        // Operations
        {"help", no_argument, 0, 'h'},
        {"path", required_argument, 0, 'p'},
        {"version", no_argument, 0, 'v'}
    };
    
    char option_char;
    int option_index;
    //optsting是选项参数组成的字符串，如果该字符串里任一字母后有冒号，那么这个选项就要求有参数。
    while ((option_char = getopt_long(argc, argv, "o:p:hv", options, &option_index)) != -1) {
        switch (option_char)
        {
            case 'p': {
                self.projectPath = [NSString stringWithUTF8String:optarg];
            }
                break;
                
            case 'o': {
                self.origPmdFilePath = [NSString stringWithUTF8String:optarg];
            }
                break;
                
            case 'h': {
                [self displayHelp];
            }
                break;
                
            case 'v': {
                [self displayVersion];
            }
                break;
                
            default:{
                [self displayHelp];
            }
                break;
        }
    }
    
    if (self.projectPath.length) {
       return [self startAnalysis];
    }
    
    return 0;
}

#pragma mark private method
- (NSInteger)startAnalysis {
    
    NSString *projecAllPath = [self getProjectPath:self.projectPath];
    // Check the path exists
    if(!projecAllPath.length || ![projecAllPath hasSuffix:@".xcodeproj"]){
        Printf(@"%@ %@\n", self.projectPath, @" 请传入包含*.xcodeproj工程文件的路径");
        return -1;
    }
    
    if (self.origPmdFilePath.length) {
        BOOL pathExists = [[NSFileManager defaultManager] fileExistsAtPath:self.origPmdFilePath];
        if (!pathExists) {
            Printf(@"%@ %@\n", self.origPmdFilePath, @" pmd文件路径找不到");
            return -1;
        }
    }

    //TODO: 两个子线程去做？
    NSLog(@"start ununsed class anaylze .......");
    NSArray<AHClassItem *> *unusedClassArray = [self.unusedClassChecker getUnusedClassWithProjectPath:projecAllPath];
    NSLog(@"start ununsed image source anaylze .......");
    NSArray<AHImageItem *> *unusedImageArray = [self.unusedImageChecker getUnusedImageInProjectPath:projecAllPath];
    NSLog(@"start ununsed reource insert report .......");
    [self.reporter startReportWithClassArray:unusedClassArray imageArray:unusedImageArray];
    
    return 1;
}

- (NSString *)getProjectPath:(NSString *)path {
    NSFileManager *fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];
    NSString *projectPath = nil;
    
    if (!isExist) {
        NSLog(@"%@ 路径无法打开", path);
        return nil;
    }
    
    if (isDir) {
        NSArray *dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
        for (NSString *str in dirArray) {
            if ([str.pathExtension isEqualToString:@"xcodeproj"]) {
                projectPath = [path stringByAppendingPathComponent:str];
                break;
            }
        }
    } else if ([path hasSuffix:@".xcodeproj"]) {
        return path;
    }

    return projectPath;
}

- (NSString *)programName {
    return [NSProcessInfo processInfo].processName;
}

- (void)displayHelp {
    Printf(@"%@ - %@", [self programName], @"扫描工程中无用类与无用资源工具.\n"
           "  usage:\n"
           "    tag -p | --add <path>   被扫描工程路径，包含*.project文件的路径\n"
           "        -o | --add <path>   报告输出的pmd文件全路径\n"
           "        -v | --version      显示版本信息\n"
           "        -h | --help         显示帮助信息\n"
           );
}

- (void)displayVersion {
    Printf(@"%@ v%@\n", [self programName], "0.0.1");
}

#pragma mark Get&Setter method
- (AHUnusedClassChecker *)unusedClassChecker {
    if (!_unusedClassChecker) {
        _unusedClassChecker = [[AHUnusedClassChecker alloc] init];
    }
    
    return _unusedClassChecker;
}

- (AHUnusedImageChecker *)unusedImageChecker {
    if (!_unusedImageChecker) {
        _unusedImageChecker = [[AHUnusedImageChecker alloc] init];
    }
    
    return _unusedImageChecker;
}

- (AHReporter *)reporter {
    if (!_reporter) {
        _reporter = [[AHReporter alloc] initWithPmdFilePath:self.origPmdFilePath];
    }
    
    return _reporter;
}

@end
