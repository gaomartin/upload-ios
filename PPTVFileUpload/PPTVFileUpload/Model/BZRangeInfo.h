//
//  BZRangeInfo.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BZRangeInfo : NSObject

@property (nonatomic, assign) long long start;
@property (nonatomic, assign) long long end;
@property (nonatomic, strong) NSString *bid;
@property (nonatomic, strong) NSString *upload_url;

@end
