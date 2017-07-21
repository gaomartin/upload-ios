//
//  DataLog.h
//  PPDAC
//
//  Created by GuoQiang Qian on 11-8-25.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DataLogSourceTypeiPhoneApp,
    DataLogSourceTypeiPadApp,
} DataLogSourceType;


@interface DataLogClient : NSObject {
    DataLogSourceType source;
}

/**
 初始化方法
 */
- (id)initWithDataLogSource:(DataLogSourceType)aSource;

/**
 创建Request对象
 */
- (NSURLRequest *)requestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items;

- (NSURLRequest *)requestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items commonItems:(NSArray *)commonItems;

- (NSURLRequest *)postRequestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items commonItems:(NSArray *)commonItems;
/**
 创建Request对象并发送
 */
- (void)sendRequestWithMetaItems:(NSArray *)metaitems items:(NSArray *)items;

/**
 创建实时用户在线的URL
 */
- (NSURL *)urlWithOnlineItems:(NSArray *)items;

// 编译字符串
- (NSString *)encodeWithString:(NSString *)string;

@property (nonatomic, assign) DataLogSourceType source;

@end
