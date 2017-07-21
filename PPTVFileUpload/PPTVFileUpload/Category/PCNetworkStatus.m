//
//  PCNetworkStatus.m
//  PPTVCommon
//
//  Created by GuoQiang Qian on 13-1-9.
//  Copyright (c) 2013年 PPTV. All rights reserved.
//

#import "PCNetworkStatus.h"

@interface PCNetworkStatus ()

@property (nonatomic, assign) PPTVReachNetworkStatus networkStatus;
@property (nonatomic, strong) PPTVReachability *reachability;

@end

@implementation PCNetworkStatus

+ (instancetype)sharedNetworkStatus
{
    static PCNetworkStatus *_sharedInstances = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstances = [[self alloc] init];
        
        _sharedInstances.reachability = [PPTVReachability reachabilityForInternetConnection];
        _sharedInstances.networkStatus = [_sharedInstances.reachability currentReachabilityStatus];
        
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserver:_sharedInstances
                                                 selector:@selector(reachabilityChanged:)
                                                     name:pptvReachabilityChangedNotification
                                                   object:_sharedInstances.reachability];
        
        // 开始网络变更通知
        [_sharedInstances.reachability startNotifier];
    });
    
    return _sharedInstances;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    // 保存当前的网络状态
    self.networkStatus = [self.reachability currentReachabilityStatus];
    
    NSString *networkStatusInfo = nil;
    
    switch (self.networkStatus) {
        case PPReachableVia2G:
            networkStatusInfo = @"2G网络";
            break;
        case PPReachableVia3G:
            networkStatusInfo = @"3G网络";
            break;
        case PPReachableVia4G:
            networkStatusInfo = @"4G网络";
            break;
        case PPReachableViaWWAN:
            networkStatusInfo = @"蜂窝网络";
            break;
        case PPReachableViaWiFi:
            networkStatusInfo = @"WiFi";
            break;
        default:
            networkStatusInfo = @"无网络";
            break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PCNetworkReachabilityChanged object:nil];
    
    NSLog(@"当前网络更新为: %@", networkStatusInfo);
}

@end
