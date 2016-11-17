//
//  BZUserModel.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BZUserModel : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *categoryid;

+ (BZUserModel *)sharedBZUserModel;


@end
