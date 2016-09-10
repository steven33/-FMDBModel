//
//  StevenHelper.h
//  封装的FMDBModel
//
//  Created by qugo on 15/9/11.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface StevenHelper : NSObject

@property (nonatomic,retain,readonly) FMDatabaseQueue *dbQueue;

+ (StevenHelper *)shareInstance;

+ (NSString *)dbPath;

@end
