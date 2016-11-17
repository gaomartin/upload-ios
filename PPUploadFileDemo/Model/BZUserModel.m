//
//  BZUserModel.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZUserModel.h"

@implementation BZUserModel

SYNTHESIZE_SINGLETON_FOR_CLASS(BZUserModel);

- (id)init
{
    if (self = [super init]) {
        self.username = @"jiahuixu@pptv.com";
        self.key = @"5FD3738DF81BACC476EF076E2BC53A34";
        self.categoryid = @"1246";
    }
    
    return self;
}

//测试账号jiahuixu@pptv.com, 密码123456

@end
