//
//  BZFileUploadDataController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZFileUploadDataController.h"
#import "PPTV_AFNetworking.h"

@implementation BZFileUploadDataController

//ttp://10.200.10.148/v1/AUTH_9960b6f099f249e5b6d726dd878aafe2/video120/74739/5676358-5676358_5515a5ff96f816a7679887e5d9170a6523eb8c04.ppc/0-OWQyZTQ0ZWEtYjBjNC00ODI0LTk4YTktYmM4ZTg1NTJiYTYz?temp_url_sig=a47a93fe206ab2e2c46a4dda58ba395f83ed21d7&temp_url_expires=1469707934
- (NSString *)requestMethod
{
    return @"POSTFILE";
}

- (NSDictionary *)requestHTTPHeaderField
{
    return self.headerField;
}

- (NSArray *)requestDataArray
{
    return [NSArray arrayWithObject:self.data];
}


@end
