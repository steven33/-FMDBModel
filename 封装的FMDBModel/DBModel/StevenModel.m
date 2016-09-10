//
//  StevenModel.m
//  封装的FMDBModel
//
//  Created by qugo on 15/9/11.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import "StevenModel.h"
#import <objc/runtime.h>
#import "StevenHelper.h"

@implementation StevenModel

#pragma mark - override method
+ (void)initialize
{
    if (self!=[StevenModel self]) {
        [self createTable];
    }
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
    }
    return self;
}

#pragma mark - must be override method
//创建表  （如果已经创建。返回YES）
+ (BOOL)createTable
{
    FMDatabase *db = [FMDatabase databaseWithPath:[StevenHelper dbPath]];
    if (![db open]) {
        NSLog(@"数据库打开失败！");
        return NO;
    }
    NSString *tableName = NSStringFromClass(self.class);
    NSString *columeAndType = [self.class getColumeAndTypeString];
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
    if (![db executeUpdate:sql]) {
        return NO;
    }
    
    NSMutableArray *columns = [NSMutableArray array];
    FMResultSet *resultSet = [db getTableSchema:tableName];
    while ([resultSet next]) {
        NSString *column = [resultSet stringForColumn:@"name"];
        [columns addObject:column];
    }
    NSDictionary *dict = [self.class getAllProperties];
    NSArray *properties = [dict objectForKey:@"name"];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
    //过滤数组
    NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
    
    for (NSString *column in resultArray) {
        NSUInteger index = [properties indexOfObject:column];
        NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
        NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
        if (![db executeUpdate:sql]) {
            return NO;
        }
    }
    
    [db close];
    return YES;
}

//保存单个数据
- (BOOL)save
{
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray array];
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
            continue;
        }
        [keyString appendFormat:@"%@,",proname];
        [valueString appendString:@"?,"];
        id value = [self valueForKey:proname];
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length -1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length -1, 1)];
    
    StevenHelper *stevDB = [StevenHelper shareInstance];
    __block BOOL res = NO;
    [stevDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);",tableName,keyString,valueString];
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
        NSLog(res?@"插入成功":@"插入失败");
//        NSLog(@"%d",self.pk);
    }];
    return res;
}
//批量保存数据对象
+ (BOOL)saveObjects:(NSArray *)array
{
    //判断是否是StevenModel的子类
    for (StevenModel *model in array) {
        if (![model isKindOfClass:[StevenModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    StevenHelper *steDB = [StevenHelper shareInstance];
    //如果iyao支持事务农=
    [steDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (StevenModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = model.columeNames[i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,",proname];
                [valueString appendFormat:@"?,"];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length -1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length -1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            NSLog(flag?@"插入成功":@"插入失败");
            NSLog(@"%d",model.pk);
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}
/** 更新单个对象 */
- (BOOL)update
{
    StevenHelper *steDB = [StevenHelper shareInstance];
    __block BOOL res = NO;
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
        for (int i = 0; i < self.columeNames.count; i++) {
            NSString *proname = [self.columeNames objectAtIndex:i];
            if ([proname isEqualToString:primaryId]) {
                continue;
            }
            [keyString appendFormat:@" %@=?,", proname];
            id value = [self valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
        }
        
        //删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, primaryId];
        [updateValues addObject:primaryValue];
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}

/** 批量更新用户对象*/
+ (BOOL)updateObjects:(NSArray *)array
{
    for (StevenModel *model in array) {
        if (![model isKindOfClass:[StevenModel class]]) {
            return NO;
        }
    }
    __block BOOL res = YES;
    StevenHelper *steDB = [StevenHelper shareInstance];
    // 如果要支持事务
    [steDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (StevenModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                res = NO;
                *rollback = YES;
                return;
            }
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@" %@=?,", proname];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [updateValues addObject:value];
            }
            
            //删除最后那个逗号
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;", tableName, keyString, primaryId];
            [updateValues addObject:primaryValue];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag?@"更新成功":@"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}




//删除单个数据
- (BOOL)deleteObject
{
    StevenHelper *steDB = [StevenHelper shareInstance];
    __block BOOL res = NO;
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}
/** 批量删除用户对象 */
+ (BOOL)deleteObjects:(NSArray *)array
{
    for (StevenModel *model in array) {
        if (![model isKindOfClass:[StevenModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    StevenHelper *steDB = [StevenHelper shareInstance];
    // 如果要支持事务
    [steDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (StevenModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                return ;
            }
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
            NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

//通过条件删除数据
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria
{
    StevenHelper *steDB = [StevenHelper shareInstance];
    __block BOOL res = NO;
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName,criteria];
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}
/** 清空表 */
+ (BOOL)clearTable
{
    StevenHelper *steDB = [StevenHelper shareInstance];
    __block BOOL res = NO;
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    return res;
}

//查询全部数据
+ (NSArray *)findAll
{
    NSLog(@"stevDB---%s",__func__);
    StevenHelper *steDB = [StevenHelper shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            StevenModel *model = [[self.class alloc] init];
            for (int i = 0 ; i < model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                }else{
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
        
    }];
    return users;
}

//查找某条数据
+ (instancetype)findFirstByCriteria:(NSString *)criteria
{
    NSArray *results = [self.class findByCriteria:criteria];
    if (results.count < 1) {
        return nil;
    }
    return [results firstObject];
}
//通过主键查询
+ (instancetype)findByPK:(int)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%d",primaryId,inPk];
    return [self findFirstByCriteria:condition];
}
//通过条件查找数据（这样可以进行分页查询 @" WHERE pk > 5 limit 10"）
+ (NSArray *)findByCriteria:(NSString *)criteria
{
    StevenHelper *steDB = [StevenHelper shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [steDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            StevenModel *model = [[self.class alloc] init];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                }else{
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    return users;
}
#pragma mark - base method
//获取该类的所有属性
+ (NSDictionary *)getPropertys
{
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray *theTransients = [[self class] transients];
    unsigned int outCount,i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTransients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         c char          C unsigned char
         i int           I unsigned int
         l long          L unsigned long
         s short         S unsigned short
         d double        D unsigned double
         f float         F unsigned float
         q long long     Q unsigned long long 
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@"NSString"
         
         64位下long 和 long long 都是Tq
         SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
         */
        if ([propertyType hasPrefix:@"T@"]) {
            [proTypes addObject:SQLTEXT];
        }else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]){
            [proTypes addObject:SQLINTEGER];
        }else{
            [proTypes addObject:SQLREAL];
        }
    }
    free(properties);
    return @{@"name":proNames,
             @"type":proTypes};
    
}
//获取所有属性，包含主键pk
+ (NSDictionary *)getAllProperties
{
    NSDictionary *dict = [self.class getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    [proNames addObject:primaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQLINTEGER,PrimaryKey]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return @{@"name":proNames,
             @"type":proTypes};
}

#pragma mark - util method
+ (NSString *)getColumeAndTypeString
{
    NSMutableString *pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i = 0; i < proNames.count; i++) {
        [pars appendFormat:@"%@ %@",proNames[i],proTypes[i]];
        if (i+1 != proNames.count) {
            [pars appendString:@","];
        }
    }
    return pars;
}

#pragma mark - must be override method
//如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写

+ (NSArray *)transients
{
    return [NSArray array];
}
@end
