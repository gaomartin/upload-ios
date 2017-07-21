//
//  DataLog.m
//  PPDAC
//
//  Created by GuoQiang Qian on 11-8-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DataLogClient.h"
#import "NSDataAdditions.h"
#import "NSString+Hashes.h"
#import "NSArray+ObjectAtIndexWithBoundsCheck.h"

//文档http://confluence:8989/pages/viewpage.action?pageId=4850490
#define DAC_SERVER_URI @"http://ppyun.data.pplive.com/1.html"
#define DAC_ENCODE_KEY @"Hy7Gi*cQPMd19XbgRsMno0dz4^sb#sQ0Unx$s!a158ScTuxPk8n6BksTcB$sc^aP"


@interface DataLogClient ()

/**
 编码字符串
 */
- (NSString *)encodeWithString:(NSString *)string;

/**
 创建路径
 */
- (NSString *)pathWithItems:(NSArray *)allitems;

- (NSString *)pathWithItems:(NSArray *)allitems commonItems:(NSArray *)commonItems;

/**
 对字符进行URL Encode
 */
- (NSString *)encodeURIComponent:(NSString *)string;

@end


@implementation DataLogClient
@synthesize source;

- (id)initWithDataLogSource:(DataLogSourceType)aSource
{
    self = [super init];
    
    if (self) {
        self.source = aSource;
    }
    
    return self;
}

// 编译字符串
- (NSString *)encodeWithString:(NSString *)string
{
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger stringLength = [stringData length];
    unsigned char *stringBytes = (unsigned char *)[stringData bytes];
    
    NSString *keyString = DAC_ENCODE_KEY;
    NSData *keyData = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger keyLength = [keyData length];
    unsigned char *keyBytes = (unsigned char *)[keyData bytes];
    
    for (int i = 0; i < stringLength; i++) {
        stringBytes[i] = (unsigned char)((int)stringBytes[i] + (int)keyBytes[i % keyLength]);
    }
    
    NSData *decodeStringData = [NSData dataWithBytes:stringBytes
                                              length:stringLength];
    
    
    return [decodeStringData base64Encoding];
}

- (NSString *)encodeURIComponent:(NSString *)string
{
    CFStringRef cfUrlEncodedString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                             (CFStringRef)string, NULL,
                                                                             (CFStringRef)@"!#$%&'()*+,/:;=?@[]",
                                                                             kCFStringEncodingUTF8);
    
    NSString *urlEncoded = [NSString stringWithString:(__bridge NSString *)cfUrlEncodedString];
    
    CFRelease(cfUrlEncodedString);
    
    return urlEncoded;
}

// 生成URL参数部分
- (NSString *)pathWithItems:(NSArray *)allitems
{
    return [self pathWithItems:allitems commonItems:nil];
}

// 生成URL参数部分
- (NSString *)pathWithItems:(NSArray *)allitems commonItems:(NSArray *)commonItems
{
    NSMutableString *formatString = nil;
    
    NSString *portType = nil;
    
    for (NSArray *item in allitems) {
//        NSAssert([item count] == 2, @"必须包括2个参数");
        
        if ([item count] != 2) {
            if (portType && [item count] > 0) {
                NSLog(@"必须包括2个参数:接口类型：%@，丢失参数的key：%@", portType, [item objectAtIndexIfIndexInBounds:0]);
            }
            continue;
        }
        
        NSString *keyValue = [item objectAtIndexIfIndexInBounds:0];
        NSString *itemValue = [item objectAtIndexIfIndexInBounds:1];
        
        if ([keyValue isEqualToString:@"A"]) {
            portType = itemValue;
        }
        
        if (commonItems == nil || ![commonItems containsObject:[item objectAtIndexIfIndexInBounds:0]]) { //判断该参数是否需要编译
            itemValue = [self encodeURIComponent:[item objectAtIndexIfIndexInBounds:1]];
        }
        if (formatString == nil) {
            formatString = [NSMutableString stringWithFormat:@"%@=%@", [self encodeURIComponent:[item objectAtIndexIfIndexInBounds:0]], itemValue];
        } else {
            [formatString appendFormat:@"&%@=%@", [self encodeURIComponent:[item objectAtIndexIfIndexInBounds:0]], itemValue];
        }
    }
    
    return [NSString stringWithString:formatString];
}
// 生成POST request body部分
- (NSData *)bodyDataWithItems:(NSArray *)allitems commonItems:(NSArray *)commonItems {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:allitems
                                    options:NSJSONWritingPrettyPrinted
                                      error:&error];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *encodeString = [self encodeWithString:json];
    NSLog(@"DAC string:%@",json);
    NSData *bodyData = [encodeString dataUsingEncoding:NSUTF8StringEncoding];
    return bodyData;
}

// 创建request对象
- (NSURLRequest *)requestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items
{
    return [self requestWithMetaItems:metaitems items:items commonItems:nil];
}

// 创建request对象
- (NSURLRequest *)requestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items commonItems:(NSArray *)commonItems
{
    NSArray *allitems = [metaitems arrayByAddingObjectsFromArray:items];
    
    NSString *path = [self pathWithItems:allitems commonItems:commonItems];

    NSString *fullURLString = [NSString stringWithFormat:@"%@?%@", DAC_SERVER_URI, [self encodeWithString:path]];
    
    NSLog(@"DAC Params:%@", path);
    //NSLog(@"DAC Request URL %@", fullURLString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    
    return request;
}

- (NSURLRequest *)postRequestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items commonItems:(NSArray *)commonItems {
    NSArray *allitems = items ? [metaitems arrayByAddingObjectsFromArray:items] : metaitems;
    
    NSData *body = [self bodyDataWithItems:allitems commonItems:commonItems];
    
    NSString *fullURLString = [NSString stringWithFormat:@"%@", DAC_SERVER_URI];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURLString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    
    return request;
}

- (void)sendRequestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items
{
    NSURLRequest *request = [self requestWithMetaItems:metaitems
                                                 items:items];
    
    [NSURLConnection connectionWithRequest:request
                                  delegate:nil];
}

- (NSURL *)urlWithOnlineItems:(NSArray *)items
{
    NSString *sourceStr = [self pathWithItems:items];
    NSData *sourceData = [sourceStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Str = [sourceData base64Encoding];
    NSString *md5Str = [NSString stringWithFormat:@"%@&#$EOQWIU31!DA421", base64Str];
    NSString *encMD5Str = [md5Str md5];
    NSString *fullURLString = [NSString stringWithFormat:@"http://ol.synacast.com/smart.html?data=%@&md5=%@", base64Str, encMD5Str];

    NSLog(@"User Online Request URL %@", fullURLString);
    
    return [NSURL URLWithString:fullURLString];
}

@end
