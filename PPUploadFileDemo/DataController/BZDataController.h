//
//  BZDataController.h
//  CargoLogistics
//
//  Created by bobzhang on 16/3/29.
//  Copyright © 2016年 张博bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BZDataControllerDelegate;

@interface BZDataController : NSObject

@property (nonatomic, strong, readonly) NSArray *retryHostsArr;
@property (nonatomic, weak) id <BZDataControllerDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval cost;
@property (nonatomic, assign) NSUInteger maxAge;
@property (nonatomic, readonly) NSDictionary *requestArgs;
@property (nonatomic, strong, readonly) NSString *dnsInfo;
@property (nonatomic, strong) NSString *aURLString;

@property (nonatomic, strong) NSURL *fullUrl;//完整的url
//服务器返回的时间
@property (nonatomic, strong) NSDate *serverReturnDate;

+ (instancetype)sharedDataController;
- (instancetype)initWithDelegate:(id <BZDataControllerDelegate>)aDelegate;

- (void)requestWithArgs:(NSDictionary *)args;
- (void)willStartRequest:(NSURLRequest *)request;
- (void)requestCancel;
- (NSString *)cacheKeyName;

- (BOOL)parseContent:(NSString *)content;
- (void)requestServerUnabled:(NSArray *)serverHosts;

- (NSString *)requestMethod;
- (NSInteger)requestTimeout;
- (NSDictionary *)requestHTTPHeaderField;
- (NSString *)requestPath;
- (NSArray *)requestDataArray;//多张文件, 多张图片
- (NSArray *)retryHosts;


@end


@protocol BZDataControllerDelegate <NSObject>
@optional
//数据请求成功
- (void)loadingDataFinished:(BZDataController *)controller;

//数据请求失败
- (void)loadingData:(BZDataController *)controller failedWithError:(NSError *)error;

@end