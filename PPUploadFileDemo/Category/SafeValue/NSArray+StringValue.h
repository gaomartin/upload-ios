//
//  NSArray+StringValue.h
//  PPTVCommon
//
//  Created by yanliu on 14-7-12.
//  Copyright (c) 2014年 PPLive Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (StringValue)

/*
 将可以调用stringValue方法的value调用stringValue
 遇到NSDictionary和NSArray继续遍历
 */
- (NSArray *)getStringValueArray;
@end
