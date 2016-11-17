//
//  BZTokenDataController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZTokenDataController.h"

@implementation BZTokenDataController

//ppcloud_portal接口文档, 2.2.21获取上传token
- (NSString *)requestPath
{
    return [NSString stringWithFormat:@"%@v1/api/token/uptoken",PPCLOUD_TEST_URL];
}

//-ttp://svc.pptvyun.com/svc/v1/api/token/uptoken?username=ppcloud-api@pptv.com&ppfeature=ppfeature&apitk=55FDAEE6A10C3E15961935F6D69A82A2
- (BOOL)parseContent:(NSString *)content
{
    BOOL retValue = NO;
    NSLog(@"uptoken content=%@",content);
    
    NSDictionary *jsonDict = [content PPJSONValue];
    
    if (jsonDict && [jsonDict isKindOfClass:[NSDictionary class]]) {
        retValue = YES;
        self.token = [jsonDict safeStringForKey:@"data"];
        self.msg = [jsonDict safeStringForKey:@"msg"];
        
        NSInteger err = [[jsonDict safeNumberForKey:@"err"] integerValue];
        if (err != 0) {
            retValue = NO;
        }
    }
    
    return retValue;
}

@end
