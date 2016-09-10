//
//  ViewController.m
//  封装的FMDBModel
//
//  Created by qugo on 15/9/11.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import "ViewController.h"
#import "User.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - 插入数据
- (IBAction)insertData:(UIButton *)sender {
    /** 1、创建多条子线程(5条子线程插入5个用户数据)
    for (int i = 0; i < 5; i++) {
        User *user = [[User alloc] init];
        user.name = [NSString stringWithFormat:@"麻子%d",i];
        user.sex = @"男";
        user.age = 10+i;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user save];
        });
    }
     */
    
    /**子线程一:插入多条用户数据（单条子线程插入5个用户数据）
        dispatch_queue_t q1 = dispatch_queue_create("queue1", NULL);
        dispatch_async(q1, ^{
            for (int i = 0; i < 5; ++i) {
                User *user = [[User alloc] init];
                user.name = @"赵五";
                user.sex = @"女";
                user.age = i+5;
                [user save];
            }
        });
     */
    
    /**主线程：（主线程插入5个用户数据）
        for (int i = 0; i < 1000; ++i) {
            User *user = [[User alloc] init];
            user.name = @"张三";
            user.sex = @"男";
            user.age = i+5;
        [user save];
    }
     */
    
    /** 子线程三：事务插入数据 */
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 1; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"李四%d",i];
            user.age = 10+i;
            user.sex = @"女";
            [array addObject:user];
        }
        [User saveObjects:array];
    });
   
}
#pragma mark - 删除数据
- (IBAction)deleteDate:(UIButton *)sender {
    //type = 0   通过条件删除数据
    //type = 1   创建多个线程删除数据
    //type = 2   子线程用事务删除数据
    //type = 3   删除表
    //type = 4
    int type = 3;
    [self deleteDateByType:type];
}
- (void)deleteDateByType:(int )type
{
    switch (type) {
        case 0:
            //通过条件删除数据
            [User deleteObjectsByCriteria:@" WHERE pk < 10"];

            break;
        case 1:
            //创建多个线程删除数据
            for (int i = 0; i < 5; i++) {
                User *user = [[User alloc] init];
                user.pk = 1+i;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [user deleteObject];
                });
            }
            break;
        case 2:
            //子线程用事务删除数据
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSMutableArray *array = [NSMutableArray array];
                for (int i = 0; i < 500; i++) {
                    User *user = [[User alloc] init];
                    user.pk = 501+i;
                    [array addObject:user];
                }
                [User deleteObjects:array];
            });
            break;
        case 3:
            //删除表
            [User clearTable];

            
            break;
        case 4:
            //

            
            break;
            
        default:
            break;
    }
}
#pragma mark - 修改数据
- (IBAction)update:(UIButton *)sender {
    //创建多个线程更新数据
    [self updateData1];
    //单个子线程批量更新数据，利用事务
    [self updateData2];
}
/** 创建多个线程更新数据 */
- (void)updateData1{
    for (int i = 0; i < 5; i++) {
        User *user = [[User alloc] init];
        user.name = [NSString stringWithFormat:@"更新%d",i];
        user.age = 120+i;
        user.pk = 5+i;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user update];
        });
    }
}

/**单个子线程批量更新数据，利用事务 */
- (void)updateData2{
    dispatch_queue_t q3 = dispatch_queue_create("queue3", NULL);
    dispatch_async(q3, ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 500; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"啊我哦%d",i];
            user.age = 88+i;
            user.pk = 10+i;
            [array addObject:user];
        }
        [User updateObjects:array];
    });
    
}
#pragma mark - 查询数据
- (IBAction)queryData:(UIButton *)sender {
    //type = 0   查询单条记录
    //type = 1   条件查询多条数据
    //type = 2   查询全部数据
    //type = 3   分页查询数据
    //type = 4   通过主键查询
    
    int type = 2;
    
    [self queryDataByType:type];
}
- (void)queryDataByType:(int )type
{
    switch (type) {
        case 0:
            //查询单条记录
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSLog(@"第一条:%@",[User findFirstByCriteria:@" WHERE age = 20 "]);
            });
            break;
        case 1:
            //条件查询多条数据
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSLog(@"小于20岁:%@",[User findByCriteria:@" WHERE age < 20 "]);
            });
            break;
        case 2:
            //查询全部数据
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSLog(@"全部:%@",[User findAll]);
            });
            break;
        case 3:
            //分页查询数据
        {
            static int pk = 10;
            NSArray *arry = [User findByCriteria:[NSString stringWithFormat:@" WHERE pk < %d limit 10",pk]];
            pk = ((User *)[arry lastObject]).pk;
            NSLog(@"array:%@",arry);
        }
            
            break;
        case 4:
            //通过主键查询
        {
            User *model = [User findByPK:3];
            NSLog(@"array:%@",model);
        }
            
            break;
            
        default:
            break;
    }
}
@end
