//
//  User.h
//  封装的FMDBModel
//
//  Created by qugo on 15/9/12.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import "StevenModel.h"

@interface User : StevenModel

/** 账号 */
@property (nonatomic, copy)     NSString                    *account;
/** 名字 */
@property (nonatomic, copy)     NSString                    *name;
/** 性别 */
@property (nonatomic, copy)     NSString                    *sex;
/** 头像地址 */
@property (nonatomic, copy)     NSString                    *portraitPath;
/** 手机号码 */
@property (nonatomic, copy)     NSString                    *moblie;
/** 简介 */
@property (nonatomic, copy)     NSString                    *descn;
/** 年龄 */
@property (nonatomic, assign)  int                          age;

@property (nonatomic, assign)   int                        height;

@property (nonatomic, assign)   int                        field1;

@property (nonatomic, assign)   int                        field2;

@end
