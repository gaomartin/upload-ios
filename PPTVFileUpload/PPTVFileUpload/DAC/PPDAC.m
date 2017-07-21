//
//  PPDAC.m
//  PPYLiveKit
//
//  Created by bobzhang on 16/11/21.
//  Copyright © 2016年 PPTV. All rights reserved.
//

#import "PPDAC.h"
#import "DataLogClient.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "PCNetworkStatus.h"
#import "UIDevice-Hardware.h"

#define PPTVFileUploadUniqueToken  @"PPTVFileUploadUniqueToken"

//日志文档http://confluence:8989/pages/viewpage.action?pageId=4850490
@interface PPDAC ()

@property (nonatomic, strong) NSMutableData *recivedData;
@property (nonatomic, strong) NSString *uniqueToken;

@end


@implementation PPDAC

+ (PPDAC *)sharedPPDAC
{
    static PPDAC *sharedPPDAC = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedPPDAC = [[self alloc] init];
    });
    return sharedPPDAC;
}

- (id)init
{
    if (self = [super init]) {
        self.uniqueToken = [self createUniqueToken];
    }
    return self;
}

- (void)sendUploadInfo
{
    /*
             ut	unique token	独立SDK标识	String	 	SDK第一次启动的时候生成，然后缓存起来，下次启动检查已存在则不生成，没有则新生成。原则上只生产一次。
             lt         log type	日志类型	enum	1- 播放，2-卡顿，3-崩溃，4-推流，5-上传
             ip         local ip	本地ip	String
             p          platform	上传来源	enum	1=web、2=js、3=ios、4=Android
             c          client	客户标识(指演出的那一方cpn)	String
             et	event time	事件(启动、播放、卡顿、崩溃等)发生时间	long	timstamp
             net      network 网络条件	enum	1=WiFi、2=4G、3=3G、4=2G、5=PC
             ts         total speed	当前并发上传速度总和	long
        */
    NSArray *uploadArray = [[PPFileUploadManager sharedFileUploadManager] currentAllUploadFiles];
    NSInteger totalSpeed = 0;
    NSString *user_id = @"";
    for (PPUploadFileData *fileData in uploadArray) {
        user_id = fileData.user_id;
    }
    
    long long obytes = [PPFileUploadManager sharedFileUploadManager].obytes;
    totalSpeed = (NSInteger)([[PPFileUploadManager sharedFileUploadManager] getInterfaceBytes] - obytes) / 10;
    
    NSString *eventTime = [NSString stringWithFormat:@"%.f",[[NSDate date] timeIntervalSince1970] * 1000];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                self.uniqueToken, @"ut",
                                [NSNumber numberWithLong:5],   @"lt" ,
                                [[UIDevice currentDevice] getIPAddress], @"ip",
                                [NSNumber numberWithInteger:3],   @"p",
                                user_id,   @"c",
                                [NSNumber numberWithLongLong:[eventTime longLongValue]],    @"et",
                                [NSNumber numberWithInteger:[[self currentNetwork] integerValue]],  @"net",
                                [NSNumber numberWithLong:labs(totalSpeed)],  @"ts",
                                nil];
    NSLog(@"sendUploadInfo");
    [self sendRequestWithParams:dic];
}

- (void)sendRequestWithParams:(NSDictionary *)params
{
    DataLogClient *dataLog;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        dataLog = [[DataLogClient alloc] initWithDataLogSource:DataLogSourceTypeiPadApp];
    } else {
        dataLog = [[DataLogClient alloc] initWithDataLogSource:DataLogSourceTypeiPhoneApp];
    }
    NSURLRequest *request = [dataLog postRequestWithMetaItems:@[params] items:nil commonItems:nil];
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        NSMutableURLRequest *postRequest = (NSMutableURLRequest *)request;
        [postRequest setHTTPMethod:@"POST"];
        
        [self sendDacWithRequest:postRequest];
    } else {
        NSURL *url = [request URL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        [request setHTTPMethod:@"GET"];
        [self sendDacWithRequest:request];
    }
}

- (void)sendDacWithRequest:(NSMutableURLRequest *)request
{
    NSLog(@"DAC the request string = %@", request.URL);
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval: 60];
    [request setHTTPShouldHandleCookies:FALSE];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (connection == nil) {
        NSLog(@"request errors");
        // 创建失败
        return;
    }
}

#pragma mark - connection
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)aResponse
{
    self.recivedData = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.recivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"DAC didFailWithError");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //TODO: dispatch_async导致NSURLConnection不走回调
    NSString *asyReturn = [[NSString alloc] initWithData:self.recivedData encoding:NSUTF8StringEncoding];
    NSLog(@"DAC asyReturn=%@",asyReturn);
}

#pragma mark - other
- (NSString *)createUniqueToken
{
    NSString *token = @"";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:PPTVFileUploadUniqueToken]) {
        token = [self createUUID];
        [defaults setObject:token forKey:PPTVFileUploadUniqueToken];
        [defaults synchronize];
    } else {
        token = [defaults objectForKey:PPTVFileUploadUniqueToken];
    }
    return token;
}

- (NSString *)createUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    
    NSString *gid = [NSString stringWithString:(__bridge NSString *)uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    return gid;
}

- (NSString *)currentNetwork
{
    //1=WiFi、2=4G、3=3G、4=2G
    NSString *network = @"0";
    switch ([[PCNetworkStatus sharedNetworkStatus] networkStatus]) {
        case PPReachableVia2G:
            network = @"4";
            break;
        case PPReachableVia3G:
            network = @"3";
            break;
        case PPReachableVia4G:
            network = @"2";
            break;
        case PPReachableViaWWAN:
            network = @"3";
            break;
        case PPReachableViaWiFi:
            network = @"1";
            break;
        default:
            break;
    }
    
    return network;
}

@end
