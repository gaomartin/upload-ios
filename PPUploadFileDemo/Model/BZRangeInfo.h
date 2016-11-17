//
//  BZRangeInfo.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BZRangeInfo : NSObject

@property (nonatomic, assign) NSInteger start;
@property (nonatomic, assign) NSInteger end;
@property (nonatomic, strong) NSString *bid;
@property (nonatomic, strong) NSString *upload_url;

@end
