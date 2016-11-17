//
//  BZUploadRangeDataController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZUploadRangeDataController.h"
#import "BZRangeInfo.h"

@implementation BZUploadRangeDataController

//ppcloud_portal接口文档, 2.2.21获取上传token
- (NSString *)requestPath
{
    return [NSString stringWithFormat:@"%@fsvc/3/file/%@/action/uploadrange", PPCLOUD_PUBLIC_TEST_URL, self.fid];
}

- (NSDictionary *)requestHTTPHeaderField
{
    return self.headerField;
}

//-ttp://svc.pptvyun.ppqa.com/svc/fsvc/3/file/43803/action/uploadrange?feature_pplive=0_da39a3ee5e6b4b0d3255bfef95601890afd80709&fromcp=ppcloud&segs=3&inner=false
- (BOOL)parseContent:(NSString *)content
{
    BOOL retValue = NO;
    NSLog(@"uploadrange content=%@",content);
    
    NSDictionary *jsonDict = [content PPJSONValue];
    
    if (jsonDict && [jsonDict isKindOfClass:[NSDictionary class]]) {
        retValue = YES;
        
        self.rangesList = [NSMutableArray array];
        
        NSDictionary *data = [jsonDict safeDictionaryForKey:@"data"];
        NSArray *ranges = [data safeArrayForKey:@"ranges"];
        
        for (int i=0; i<[ranges count]; i++) {
            BZRangeInfo *info = [[BZRangeInfo alloc] init];
            NSDictionary *rangeDict = [ranges objectAtIndex:i];
            info.start = [[rangeDict safeNumberForKey:@"start"] integerValue];
            info.end = [[rangeDict safeNumberForKey:@"end"] integerValue];
            info.bid = [rangeDict safeStringForKey:@"bid"];
            info.upload_url = [rangeDict safeStringForKey:@"upload_url"];
            
            [self.rangesList addObject:info];
        }
    }
    
    return retValue;
}


@end
