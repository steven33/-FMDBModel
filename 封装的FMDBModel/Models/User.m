//
//  User.m
//  封装的FMDBModel
//
//  Created by qugo on 15/9/12.
//  Copyright (c) 2015年 qugo. All rights reserved.
//

#import "User.h"

@interface User ()

@property(nonatomic,copy)NSString *duty;

@end

@implementation User
#pragma mark - override method
+(NSArray *)transients
{
    return [NSArray arrayWithObjects:@"duty",nil];
}

@end
