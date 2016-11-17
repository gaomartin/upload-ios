//
//  NSString+PPURL.m
//  PPTVCommon
//
//  Created by GuoQiang Qian on 14-6-25.
//  Copyright (c) 2014年 PPLive Corporation. All rights reserved.
//

#import "NSString+PPURL.h"

@implementation NSString (PPURL)

- (NSString *)URLEncodedString
{
    NSString *result = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                 kCFStringEncodingUTF8));
    return result;
}

- (NSString *)URLDecodedString
{
    NSString *result = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                 (CFStringRef)self,
                                                                                                 CFSTR(""),
                                                                                                 kCFStringEncodingUTF8));
    return result;
}

@end
