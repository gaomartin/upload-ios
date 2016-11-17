//
//  NSDictionary+StringValue.m
//  PPTVCommon
//
//  Created by yanliu on 14-7-12.
//  Copyright (c) 2014年 PPLive Corporation. All rights reserved.
//

#import "NSDictionary+StringValue.h"
#import "NSArray+StringValue.h"

@implementation NSDictionary (StringValue)

- (NSDictionary *)getStringValueDict
{
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:self];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            newDic[key] = [obj getStringValueArray];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            newDic[key] = [obj getStringValueDict];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            newDic[key] = [obj stringValue];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            [newDic removeObjectForKey:key];
        }
    }];
    
    return [NSDictionary dictionaryWithDictionary:newDic];
}

@end
