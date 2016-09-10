//
//  StevenModel.h
//  封装的FMDBModel
//
//  Created by qugo on 15/9/11.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**  SQLite五种数据类型   */
#define SQLTEXT      @"TEXT"     //值是文本字符串，使用数据库编码（UTF-8，UTF-16BE或者UTF-16LE）
#define SQLINTEGER   @"INTEGER"  //值是有符号整形，根据值得大小以1，2，3，4，6或8字节存放
#define SQLREAL      @"REAL"     //值是浮点型值，以8字节IEEE浮点数存放
#define SQLBLOB      @"BLOB"     //只是一个数据块，完全按照输入存放（即没有准换）
#define SQLNULL      @"NULL"     //值是NULL

#define PrimaryKey   @"primary key"  //主键
#define primaryId    @"pk"           //原标识

@interface StevenModel : NSObject

//主键 id
@property (nonatomic, assign) int   pk;
//列名
@property (retain,readonly,nonatomic) NSMutableArray *columeNames;
//列类型
@property (retain,readonly,nonatomic) NSMutableArray *columeTypes;


//获取该类的所有属性
+ (NSDictionary *)getPropertys;
//获取所有属性，包括主键
+ (NSDictionary *)getAllProperties;

//保存单个数据
- (BOOL)save;
//批量保存数据
+ (BOOL)saveObjects:(NSArray *)array;


//删除单个数据
- (BOOL)deleteObject;
//批量删除数据
+ (BOOL)deleteObjects:(NSArray *)array;
//通过条件删除数据
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria;
//清空表
+ (BOOL)clearTable;

//更新单个数据
- (BOOL)update;
//批量更新数据
+ (BOOL)updateObjects:(NSArray *)array;


//查询全部数据
+ (NSArray *)findAll;
//查找某条数据
+ (instancetype)findFirstByCriteria:(NSString *)criteria;
//通过条件查找数据（这样可以进行分页查询 @" WHERE pk > 5 limit 10"）
+ (NSArray *)findByCriteria:(NSString *)criteria;
//通过主键查询
+ (instancetype)findByPK:(int)inPk;



#pragma mark - must be override method
//创建表  （如果已经创建。返回YES）
+ (BOOL)createTable;
//如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
+ (NSArray *)transients;
@end
