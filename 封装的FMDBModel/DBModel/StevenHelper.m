//
//  StevenHelper.m
//  封装的FMDBModel
//
//  Created by qugo on 15/9/11.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import "StevenHelper.h"

@interface StevenHelper ()

@property (nonatomic,retain) FMDatabaseQueue *dbQueue;

@end

@implementation StevenHelper

static StevenHelper *_instance = nil;

+ (StevenHelper *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (NSString *)dbPath
{
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *fileManage = [NSFileManager defaultManager];
    docsdir = [docsdir stringByAppendingPathComponent:@"STEVEN"];
    BOOL isDir;
    BOOL exit = [fileManage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [fileManage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"steven.sqlite"];
    return dbpath;
}

- (FMDatabaseQueue *)dbQueue
{
    if (!_dbQueue) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class dbPath]];
    }
    return _dbQueue;
}



+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [StevenHelper shareInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [StevenHelper shareInstance];
}

#if ! __has_feature(objc_arc)
- (oneway void)release
{
    
}

- (id)autorelease
{
    return _instance;
}

- (NSUInteger)retainCount
{
    return 1;
}
#endif

@end
