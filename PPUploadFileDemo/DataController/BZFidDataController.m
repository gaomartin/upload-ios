//
//  BZFidDataController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/27.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZFidDataController.h"

@implementation BZFidDataController

- (NSString *)requestMethod
{
    return @"POST";
}

//http://www.pptvyun.com/doc/java_api.html#创建视频
- (NSString *)requestPath
{
    return [NSString stringWithFormat:@"%@v1/api/channel/upload",PPCLOUD_TEST_URL];
}

- (BOOL)parseContent:(NSString *)content
{
    BOOL retValue = NO;
    NSLog(@"fid content=%@",content);
    
    NSDictionary *jsonDict = [content PPJSONValue];
    
    if (jsonDict && [jsonDict isKindOfClass:[NSDictionary class]]) {
        retValue = YES;
        
        NSDictionary *data = [jsonDict safeDictionaryForKey:@"data"];
        
        self.fid = [[data safeNumberForKey:@"fId"] stringValue];
        self.transcodeStatus = [[data safeNumberForKey:@"transcodeStatus"] integerValue];
        
    }
    
    return retValue;
}


@end
