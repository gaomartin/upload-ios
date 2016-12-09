//
//  NSArray+StringValue.m
//  PPTVCommon
//
//  Created by yanliu on 14-7-12.
//  Copyright (c) 2014年 PPLive Corporation. All rights reserved.
//

#import "NSArray+StringValue.h"
#import "NSDictionary+StringValue.h"

@implementation NSArray (StringValue)

- (NSArray *)getStringValueArray
{
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            newArray[idx] = [obj getStringValueArray];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            newArray[idx] = [obj getStringValueDict];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            newArray[idx] = [obj stringValue];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            [newArray removeObjectAtIndex:idx];
        }
    }];
    
    return [NSArray arrayWithArray:newArray];
}

@end
