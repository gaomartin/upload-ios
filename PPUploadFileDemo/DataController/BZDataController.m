//
//  BZDataController.m
//  CargoLogistics
//
//  Created by bobzhang on 16/3/29.
//  Copyright © 2016年 张博bobzhang. All rights reserved.
//

#import "BZDataController.h"
#import "PPTV_AFHTTPRequestOperation.h"
#import "NSString+PPURL.h"
#import "NSArray+ObjectAtIndexWithBoundsCheck.h"
#import "BZDataCache.h"
//#import "PCNetworkStatus.h"

#import <netinet/in.h>
#import <arpa/inet.h>

static NSMutableDictionary *sharedInstances = nil;

NSString *const DataControllerErrorDomain = @"BZDataControllerErrorDomain";

@interface BZDataController ()

@property (nonatomic, strong) NSArray *retryHostsArr;

@property (nonatomic, strong) NSDate *startRequestDate;
@property (nonatomic, strong) PPTV_AFHTTPRequestOperation *httpOperation;

@property (nonatomic, strong) void (^selfRetainBlock)(void);

@property (nonatomic, strong) void (^successBlock)(BZDataController *);
@property (nonatomic, strong) void (^failureBlock)(BZDataController *, NSError *);

- (NSURL *)makeURLWithArgs:(NSDictionary *)args;
- (NSString *)makeQueryStringFromArgs:(NSDictionary *)args;

- (void)requestWithAFNetworking:(NSURLRequest *)request;

- (void)getResponseInfoWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation;
- (void)requestFinishedWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation;
- (void)requestFailedWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation;

- (void)requestCancelWithAFNetworking;


@end

@implementation BZDataController


+ (instancetype)sharedDataController
{
    BZDataController *aController;
    
    @synchronized(self)
    {
        if (sharedInstances == nil) {
            sharedInstances = [[NSMutableDictionary alloc] init];
        }
        
        NSString *keyName = NSStringFromClass([self class]);
        
        aController = [sharedInstances objectForKey:keyName];
        
        if (aController == nil) {
            aController = [[self alloc] init];
            
            [sharedInstances setObject:aController
                                forKey:keyName];
        }
    }
    
    return aController;
}

- (instancetype)initWithDelegate:(id <BZDataControllerDelegate>)aDelegate
{
    self = [self init];
    
    if (self) {
        self.delegate = aDelegate;
        self.httpOperation = nil;
        self.startRequestDate = nil;
        self.aURLString = nil;
    }
    
    return self;
}

- (void)dealloc
{
    _requestArgs = nil;
    self.delegate = nil;
    
    if (self.httpOperation != nil) {
        [self.httpOperation cancel];
        self.httpOperation = nil;
    }
    
    self.startRequestDate = nil;
    self.serverReturnDate = nil;
}

- (NSURL *)makeURLWithArgs:(NSDictionary *)args
{
    if (self.fullUrl) {
        return self.fullUrl;
    }
    
    NSMutableString *formatString = nil;
    
    for (NSString *key in args) {
        if (formatString == nil) {
            formatString = [NSMutableString stringWithFormat:@"%@=%@", key, [[args valueForKey:key] URLEncodedString]];
        } else {
            [formatString appendFormat:@"&%@=%@", key, [[args valueForKey:key] URLEncodedString]];
        }
    }
    
    if (formatString) {
        if ([[self requestPath] rangeOfString:@"?"].location == NSNotFound) {
            self.aURLString = [NSString stringWithFormat:@"%@?%@", [self requestPath], formatString];
        } else {
            self.aURLString = [NSString stringWithFormat:@"%@&%@", [self requestPath], formatString];
        }
    } else {
        self.aURLString = self.requestPath;
    }
    
    NSURL *newUrl = [NSURL URLWithString:self.aURLString];
    
    if (self.retryHostsArr &&
        self.retryHostsArr.count > 0) {
        newUrl = [self replaceHostWith:[self.retryHostsArr objectAtIndexIfIndexInBounds:0]
                                oldUrl:[NSURL URLWithString:self.aURLString]];
        
        self.aURLString = newUrl.absoluteString;
    }
    
    return newUrl;
}

- (NSString *)makeQueryStringFromArgs:(NSDictionary *)args
{
    NSMutableString *formatString = nil;
    
    for (NSString *key in args) {
        if (formatString == nil) {
            formatString = [NSMutableString stringWithFormat:@"%@=%@", key, [[args valueForKey:key] URLEncodedString]];
        } else {
            [formatString appendFormat:@"&%@=%@", key, [[args valueForKey:key] URLEncodedString]];
        }
    }
    
    return [NSString stringWithString:formatString];
}

- (void)requestWithArgs:(NSDictionary *)args
{
    _requestArgs = nil;
    
    _requestArgs = args;
    
    // 取消当前的请求
    [self requestCancel];
    
    NSString *cache = nil;
    
    //DDLogDebug(@"Request URL: %@", [self makeURLWithArgs:args]);
    
    // 尝试读取缓存
    if ([self cacheKeyName] != nil) {
        BZDataCache *dataCache = [BZDataCache sharedBZDataCache];
        
        cache = [dataCache cacheForKey:[self cacheKeyName]];
    }
    
    
    NSMutableURLRequest *urlRequest = nil;
    
    if ([self.requestMethod isEqualToString:@"GET"]) {
        urlRequest = [NSMutableURLRequest requestWithURL:[self makeURLWithArgs:args]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:[self requestTimeout]];
        [urlRequest setHTTPMethod:@"GET"];
    } else if ([self.requestMethod isEqualToString:@"POST"]) {
        urlRequest = [NSMutableURLRequest requestWithURL:[self makeURLWithArgs:args]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:[self requestTimeout]];
        
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setValue:@"application/x-www-form-urlencoded; charset=UTF-8"
          forHTTPHeaderField:@"Content-Type"];
        
        if (args && args.count > 0) {
            [urlRequest setHTTPBody:[[self makeQueryStringFromArgs:args] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    } else if ([self.requestMethod isEqualToString:@"POSTFILE"]) {//文件
        //假如requestHTTPBody不为空，则可以认为是需要上传图片的POST请求类型
        
        //根据url初始化request
        urlRequest = [NSMutableURLRequest requestWithURL:[self makeURLWithArgs:args]
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:[self requestTimeout]];
        
        NSString *TWITTERFON_FORM_BOUNDARY = @"wuliuxiangmuAaB03x";//boundary本身没有特殊要求，只要不会和其他内容混淆就好，所以尽量复杂些
        
        //分界线 --AaB03x
        NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
        //结束符 AaB03x--
        NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
        
        //声明myRequestData，用来放入http body
        NSMutableData *myRequestData=[NSMutableData data];
        
        for (int i=0; i<[self.requestDataArray count]; i++) {
            //http body的字符串
            NSMutableString *body=[[NSMutableString alloc]init];
            
            NSData* data = [self.requestDataArray objectAtIndexIfIndexInBounds:i];
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            
            //声明name字段，文件名filename
            [body appendFormat:@"Content-Disposition: form-data; name=\"photo\"; filename=\"image.png\"\r\n"];
            
            //声明上传文件的格式
            [body appendFormat:@"Content-Type: image/png\r\n\r\n"];
            
            //声明结束符：--AaB03x--
            NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
            
            //将body字符串转化为UTF8格式的二进制
            [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
            //将image的data加入
            [myRequestData appendData:data];
            //加入结束符--AaB03x--
            [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
        }
       
        
        //设置HTTPHeader中Content-Type的值
        NSString *content = [[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@", TWITTERFON_FORM_BOUNDARY];
        //设置HTTPHeader
        [urlRequest setValue:content forHTTPHeaderField:@"Content-Type"];
        //设置Content-Length
        [urlRequest setValue:[NSString stringWithFormat:@"%tu", [myRequestData length]] forHTTPHeaderField:@"Content-Length"];
        NSLog(@"Content-Length:%tu", [myRequestData length]);
        //设置http body
        [urlRequest setHTTPBody:myRequestData];
        //http method
        [urlRequest setHTTPMethod:@"POST"];
    }
    
    //设置Http header
    if (self.requestHTTPHeaderField && self.requestHTTPHeaderField.count > 0) {
        [self.requestHTTPHeaderField enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [urlRequest addValue:value
              forHTTPHeaderField:key];
        }];
    }
    
    if (cache == nil) {
        [self requestWithAFNetworking:urlRequest];
    } else {
        if ([self parseContent:cache]) {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(loadingDataFinished:)]) {
                [self.delegate performSelector:@selector(loadingDataFinished:)
                                    withObject:self];
            }
            
            if (self.successBlock) {
                self.successBlock(self);
            }
            
            self.successBlock = nil;
            self.failureBlock = nil;
        } else {
            NSAssert(NO, @"缓存了错误的接口");
            
            [self requestWithAFNetworking:urlRequest];
        }
    }
}

- (void)requestWithAFNetworking:(NSURLRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // 通过自引用，使datacontroller在请求时不被释放。
    self.selfRetainBlock = ^ {
        [self description];
    };
#pragma clang diagnostic pop
    
    
    NSLog(@"AFNetworking Request: %@", request.URL);
    
    [self willStartRequest:request];
    
    PPTV_AFHTTPRequestOperation *newHttpOperation = [[PPTV_AFHTTPRequestOperation alloc] initWithRequest:request];
    self.httpOperation = newHttpOperation;
    newHttpOperation = nil;
    
    self.httpOperation.securityPolicy.allowInvalidCertificates = YES;
    
    __weak BZDataController *weakSelf = self;
    [self.httpOperation setCompletionBlockWithSuccess:^(PPTV_AFHTTPRequestOperation *operation, id responseObject) {
        [weakSelf requestFinishedWithAFNetworking:operation];
        
        weakSelf.selfRetainBlock = nil;
    } failure:^(PPTV_AFHTTPRequestOperation *operation, NSError *error) {
        [weakSelf requestFailedWithAFNetworking:operation];
        
        weakSelf.selfRetainBlock = nil;
    }];
    
    // 设置请求的开始时间
    self.startRequestDate = [NSDate date];
    
    [self.httpOperation start];
}

- (void)willStartRequest:(NSURLRequest *)request
{
    // 空实现
}

- (void)requestCancel
{
    [self requestCancelWithAFNetworking];
}

- (void)requestCancelWithAFNetworking
{
    if (self.httpOperation != nil) {
        [self.httpOperation cancel];
        self.httpOperation = nil;
    }
}

#pragma mark - AFNetworking Method
- (void)getResponseInfoWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation
{
    BOOL needReport = YES;
    
    NSDictionary *headerFields = [[operation response] allHeaderFields];
    NSString *currentDateStr = [headerFields objectForKey:@"Date"];
    NSDate *date = nil;
    if (currentDateStr) {
        date = [self dateFromDayString:currentDateStr];
    }
    self.serverReturnDate = date;
    
    
    self.cost = [[NSDate date] timeIntervalSinceDate:self.startRequestDate];
    
    // 判断请求成功时，但时间没有超过阀值
    if ([operation.response statusCode] == 200) {
        // 判断是否需要发送
        double maxreporttimeValue = 5.0;
        
        if (self.cost < maxreporttimeValue) {
            needReport = NO;
        }
    }
    
    self.startRequestDate = nil;
}

- (void)requestFinishedWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation
{
    NSLog(@"AFNetworking operation successed");
    [self getResponseInfoWithAFNetworking:operation];
    
    NSInteger statusCode = operation.response.statusCode;
    
    if (200 == statusCode) {
        if ([self parseContent:[operation responseString]]) {
            if ([self cacheKeyName] != nil) {
                BZDataCache *dataCache = [BZDataCache sharedBZDataCache];
                
                [dataCache setCache:[operation responseString]
                             forKey:[self cacheKeyName]];
            }
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(loadingDataFinished:)]) {
                [self.delegate performSelector:@selector(loadingDataFinished:)
                                    withObject:self];
            }
            
            if (self.successBlock) {
                self.successBlock(self);
            }
            
            self.successBlock = nil;
            self.failureBlock = nil;
        } else {
            NSError *error = [NSError errorWithDomain:DataControllerErrorDomain
                                                 code:100
                                             userInfo:nil];
            
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(loadingData:failedWithError:)]) {
                [self.delegate performSelector:@selector(loadingData:failedWithError:)
                                    withObject:self
                                    withObject:error];
            }
            
            if (self.failureBlock) {
                self.failureBlock(self, error);
            }
            
            self.successBlock = nil;
            self.failureBlock = nil;
        }
    } else {
        //判断是否是服务器异常
        BOOL isRetry = NO;
        
        if (statusCode >= 400) {
            isRetry = [self hostRetry:[operation.request URL]];
        }
        
        if (!isRetry) {
            [self requestServerUnabled:self.retryHostsArr ? self.retryHostsArr : @[operation.request.URL.host]];
            
            NSError *error = [NSError errorWithDomain:DataControllerErrorDomain
                                                 code:101
                                             userInfo:nil];
            //处理delegate方法
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(loadingData:failedWithError:)]) {
                [self.delegate performSelector:@selector(loadingData:failedWithError:)
                                    withObject:self
                                    withObject:error];
            }
            
            if (self.failureBlock) {
                self.failureBlock(self, error);
            }
            
            self.successBlock = nil;
            self.failureBlock = nil;
            
            self.httpOperation = nil;
        }
    }
}

- (NSArray *)retryHostsArr
{
    if (!_retryHostsArr) {
        NSArray *retryHosts = [self retryHosts];
        if (!retryHosts || retryHosts.count <= 0) {
            _retryHostsArr = nil;
            return _retryHostsArr;
        }
        
        NSMutableArray *tempArr = [NSMutableArray arrayWithArray:retryHosts];
        
        //让hosts里面的地址截取host eg:http://www.BZtv.com and www.BZtv.com
        NSMutableArray *realHosts = [NSMutableArray array];
        for (NSString *theUrl in tempArr) {
            NSURL *url = [NSURL URLWithString:theUrl];
            if (url.scheme) {
                [realHosts addObject:url.host];
                continue;
            }
            [realHosts addObject:theUrl];
        }
        tempArr = realHosts;
        
        //去除重复
        NSMutableArray *noRepeatArr = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < [tempArr count]; i++) {
            if ([noRepeatArr containsObject:[tempArr objectAtIndex:i]] == NO) {
                [noRepeatArr addObject:[tempArr objectAtIndex:i]];
            }
        }
        tempArr = noRepeatArr;
        
        _retryHostsArr = [NSArray arrayWithArray:tempArr];
    }
    return _retryHostsArr;
}

- (BOOL)hostRetry:(NSURL *)curentUrl
{
    NSString *host = curentUrl.host;
    
    NSArray *hosts = self.retryHostsArr;
    
//    //以下条件终止重试
//    if ([[PCNetworkStatus sharedNetworkStatus] networkStatus] == NotReachable ||
//        !hosts ||
//        hosts.count <= 0 ||
//        !curentUrl ||
//        !host ||
//        host.length <= 0
//        ) {
//        return NO;
//    }
    
    NSInteger index = [hosts indexOfObject:host];
    
    if (index > hosts.count || index < 0) {
        index = -1;
    }
    
    NSString *nextHost = [hosts objectAtIndexIfIndexInBounds:index + 1];
    
    if (!nextHost || nextHost.length == 0) {
        return NO;
    }
    
    NSMutableURLRequest *newUrlRequest = [self.httpOperation.request mutableCopy];
    
    NSURL *url = self.httpOperation.request.URL;
    
    NSURL *newUrl = [self replaceHostWith:nextHost oldUrl:url];
    
    newUrlRequest.URL = newUrl;
    
    if (!newUrlRequest) {
        return NO;
    }
    
    [self requestCancelWithAFNetworking];
    
    [self requestWithAFNetworking:newUrlRequest];
    
    return YES;
}

- (NSURL *)replaceHostWith:(NSString *)newHost oldUrl:(NSURL *)oldUrl
{
    if (!newHost ||
        newHost.length == 0 ||
        !oldUrl) {
        return nil;
    }
    
    NSString *oldHost = [oldUrl host];
    NSMutableString *urlString = [NSMutableString stringWithString:oldUrl.absoluteString];
    [urlString replaceOccurrencesOfString:oldHost
                               withString:newHost
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, [urlString length])];
    
    return [NSURL URLWithString:urlString];
}

- (void)requestFailedWithAFNetworking:(PPTV_AFHTTPRequestOperation *)operation
{
    NSLog(@"AFNetworking Request failed  URL: %@ \n Error code: %zd \n Description: %@ \n", operation.request.URL, [operation.error code], [operation.error localizedDescription]);
    
    [self getResponseInfoWithAFNetworking:operation];
    
    //如果请求超时可以并且有网络，可以认为登陆失败，将切换标志位设置YES，
    //实例先对错误做处理，接着再交给delegate做处理，防止再次请求可能会导致相关错误
    BOOL isRetry = [self hostRetry:[operation.request URL]];
    
    if (!isRetry) {
        [self requestServerUnabled:self.retryHostsArr ? self.retryHostsArr : @[operation.request.URL.host]];
        
        //处理delegate方法
        if (self.delegate
            && [self.delegate respondsToSelector:@selector(loadingData:failedWithError:)]) {
            [self.delegate performSelector:@selector(loadingData:failedWithError:)
                                withObject:self
                                withObject:operation.error];
        }
        
        if (self.failureBlock) {
            self.failureBlock(self, operation.error);
        }
        
        self.successBlock = nil;
        self.failureBlock = nil;
        
        self.httpOperation = nil;
    }
}

#pragma mark - Class Method
- (BOOL)parseContent:(NSString *)content
{
    // 子类自己实现
    NSAssert(NO, @"require implementation");
    
    return NO;
}

- (void)requestServerUnabled:(NSArray *)serverHosts
{
    //针对服务器不可用状况的处理，替代原来不合理的方法名称
}

- (NSString *)cacheKeyName
{
    // 如果需要支持缓存，必须实现该方法
    return nil;
}

- (NSString *)requestMethod
{
    //子类根据需要使用POST，一般情况下为GET
    return @"GET";
}

- (NSInteger)requestTimeout
{
    return 15;
}

- (NSDictionary *)requestHTTPHeaderField
{
    //子类根据需要使用
    return nil;
}

- (NSString *)requestPath
{
    // 子类自己实现
    NSAssert(NO, @"require implementation");
    
    return @"";
}

- (NSArray *)requestDataArray
{
    //子类根据需要实现
    
    return nil;
}

- (NSArray *)retryHosts
{
    //子类根据需要实现
    
    return nil;
}

- (NSDate *)dateFromDayString:(NSString *)dayString
{
    static NSDateFormatter *formatter = nil;
    
    if (!formatter) {
        @synchronized(self) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en"]];
            [formatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss z"];
        }
    }
    
    return [formatter dateFromString:dayString];
}


@end
